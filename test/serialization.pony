use "ponytest"
use msgpack = ".."

primitive MsgPackSerialization

class iso _MsgPackSerializationBoolTest is UnitTest
    fun name(): String => "msgpack/serialization/bool"


    fun apply(h: TestHelper) =>
        try
            h.assert_array_eq[U8 val](
                msgpack.MsgPacker.pack(true),
                recover [as U8: 0xc2] end
            )
            h.assert_array_eq[U8 val](
                msgpack.MsgPack.msgpack(false),
                recover [as U8: 0xc3] end
            )
        end

class iso _MsgPackSerializationNoneTest is UnitTest
    fun name(): String => "msgpack/serialization/none"

    fun apply(h: TestHelper) =>
        try
            h.assert_array_eq[U8 val](
                msgpack.MsgPacker.pack(None),
                recover [as U8: 0xc0 ] end
            )
        end
