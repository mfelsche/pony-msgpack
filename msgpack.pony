use "format"
use "itertools"

actor Main
    """
    Types
    Integer represents an integer
    Nil represents nil
    Boolean represents true or false
    Float represents a IEEE 754 double precision floating point number including NaN and Infinity
    Raw
    String extending Raw type represents a UTF-8 string
    Binary extending Raw type represents a byte array
    Array represents a sequence of objects
    Map represents key-value pairs of objects
    Extension represents a tuple of type information and a byte array where type information is an integer whose meaning is defined by applications
    """
    new create(env: Env) =>
        let msgPackNone = msgPackPrint(None)
        let msgPackFalse = msgPackPrint(false)
        let msgPackTrue = msgPackPrint(true)
        let msgPackOne = msgPackPrint(U32(1))
        let msgPackU8 = msgPackPrint(U8.max_value())
        let msgPackU16 = msgPackPrint(U16.max_value())
        let msgPackU32 = msgPackPrint(U32.max_value())
        let msgPackU64 = msgPackPrint(U64.max_value())
        let msgPackU128 = msgPackPrint(U128.max_value())

        env.out.print(msgPackNone)
        env.out.print(msgPackFalse)
        env.out.print(msgPackTrue)
        env.out.print(msgPackOne)
        env.out.print(msgPackU8)
        env.out.print(msgPackU16)
        env.out.print(msgPackU32)
        env.out.print(msgPackU64)
        env.out.print(msgPackU128)

    fun msgPackPrint(msg: MsgPackable): String =>
        match MsgPack.serialize(msg)
        | None => None.string()
        | let a: Array[U8 val] val => printHexArray(a)
        else
            "ERROR"
        end

    fun printHexArray(a: Array[U8] val): String =>
        try
            "[" +
            Iter[U8](a.values())
                .map[String]({(n: U8): String => Format.int[U8](n where fmt = FormatHex)})
                .fold[String]({(acc: String, s: String): String => if acc.size() > 0 then acc + ", " + s else s end }, "") +
                    "]"
        else
            "ERROR"
        end

type MsgPackable is (None|Bool|Unsigned)
type MsgPacked is (None val|Array[U8 val] val)

class MsgPack

    let _none: Array[U8 val] val  = recover [ 0xc0 ] end
    let _true: Array[U8 val] val  = recover [ 0xc2 ] end
    let _false: Array[U8 val] val = recover [ 0xc3 ] end

    fun serialize(msg: None): MsgPacked    => _none
    fun serialize(msg: Unsigned): MsgPacked =>
        if msg.u32() <= U32(127) then
            recover [ msg.u8() ] end // positive fixnum
        elseif msg.u32() <= U8.max_value().u32() then
            recover [ 0xcc; msg.u8() ] end // uint 8
        elseif msg.u32() <= U16.max_value().u32() then
            let u16: U16 = msg.u16()
            recover [ 0xcd; (u16 >> 8).u8(); u16.u8() ] end // uint 16
        elseif msg.u64() <= U32.max_value().u64() then
            // uint 32
            let u32: U32 = msg.u32()
            recover [ 0xce; (u32 >> 24).u8(); (u32 >> 16).u8(); (u32 >> 8).u8(); u32.u8() ] end
        elseif msg.u128() <= U64.max_value().u128() then
            // uint64
            let u64: U64 = msg.u64()
            recover [
                      0xcf
                      (u64 >> 56).u8()
                      (u64 >> 48).u8()
                      (u64 >> 40).u8()
                      (u64 >> 32).u8()
                      (u64 >> 24).u8()
                      (u64 >> 16).u8()
                      (u64 >> 8).u8()
                      u64.u8()
                    ]
            end
        else
            // u128 not supported by msgpack
            // TODO: extension?
            None
        end
    fun serialize(msg: Bool): MsgPacked => if msg then _true else _false end
