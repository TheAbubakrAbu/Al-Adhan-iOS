import Foundation
import Compression

// The `.json.xz` payloads the Islam tab reads (the Miracles library, Hisn al-Muslim, the Names'
// depth pack, the Reminder of the Day corpus) are LZMA. Al-Islam gets this decompressor from the
// Quran module's `SolidPack`, which this app does not ship; the type keeps that name so the reading
// code is identical across the three apps.
enum SolidPack {
    static func xzDecompress(_ data: Data) -> Data? {
        let bufferSize = 1 << 20
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        // compression_stream has no empty initializer in Swift; these fields are
        // overwritten by compression_stream_init and the loop before first use.
        var stream = compression_stream(dst_ptr: buffer, dst_size: 0, src_ptr: buffer, src_size: 0, state: nil)
        guard compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, COMPRESSION_LZMA)
            == COMPRESSION_STATUS_OK else { return nil }
        defer { compression_stream_destroy(&stream) }

        var out = Data()
        // The xz container carries no decompressed size up front; the packs this reads inflate 3x to
        // 50x, so a 4x reservation spares the first few doublings without over-committing (step 7).
        out.reserveCapacity(min(data.count * 4, 64 * 1024 * 1024))
        let finished: Bool? = data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> Bool? in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return nil }
            stream.src_ptr = base
            stream.src_size = data.count
            while true {
                stream.dst_ptr = buffer
                stream.dst_size = bufferSize
                switch compression_stream_process(&stream, Int32(COMPRESSION_STREAM_FINALIZE.rawValue)) {
                case COMPRESSION_STATUS_END:
                    out.append(buffer, count: bufferSize - stream.dst_size)
                    return true
                case COMPRESSION_STATUS_OK:
                    // A full pass with no output and no input left would spin forever: bail.
                    guard bufferSize - stream.dst_size > 0 || stream.src_size > 0 else { return false }
                    out.append(buffer, count: bufferSize - stream.dst_size)
                default:
                    return false
                }
            }
        }
        return finished == true ? out : nil
    }
}
