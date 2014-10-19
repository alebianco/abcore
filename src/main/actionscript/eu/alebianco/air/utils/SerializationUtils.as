package eu.alebianco.air.utils
{
	import flash.utils.ByteArray;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	public class SerializationUtils
	{
		public static function toString(value:Object):String
		{
			if (value === null) {
				return '';
			}
			
			var bytes:ByteArray       = new ByteArray();
			var encoder:Base64Encoder = new Base64Encoder();
			
			bytes.writeObject(value);
			bytes.position = 0;
			encoder.encodeBytes(bytes);
			
			return encoder.toString();           
		}
		
		public static function fromString(value:String):Object
		{
			if (value === null) {
				return null;
			}
			
			var decoder:Base64Decoder = new Base64Decoder();
			var result:ByteArray      = null;
			
			decoder.decode(value);
			
			result          = decoder.toByteArray();
			result.position = 0; 
			
			return result.readObject();   
		}
		
	}
}