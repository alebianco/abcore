package eu.alebianco.air.utils
{
	import com.adobe.crypto.MD5;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	final public class ImageCacheManager
	{
		private static var instance:ImageCacheManager;
		private static var canCreate:Boolean = false;
		
		private const DEFAULT_CACHE_PATH:String = "app-storage:/cachedimages/";
		
		private var queue:Array = [];
		
		private var _basepath:String = DEFAULT_CACHE_PATH;
		private var _request:URLRequest;
		private var _loader:URLLoader;
		private var _file:File;
		private var _stream:FileStream;
		
		public static function getInstance():ImageCacheManager
		{
			if (instance == null)
			{
				canCreate = true;
				instance = new ImageCacheManager();
				canCreate = false;
			}
			
			return instance;
		}
		
		public function ImageCacheManager()
		{
			if (!canCreate)
			{
				throw new Error("Can't instantiate a Singleton Class. Use the getInstance() method to get a reference.");
			}
		}
		
		public function get cacheDirectoryPath():String
		{
			file.url = _basepath;
			return _file.nativePath;
		}
		
		public function set cacheDirectoryPath(value:String):void
		{
			try
			{
				file.url = value;
				file.canonicalize();
				_basepath = _file.url;
			}
			catch(error:Error)
			{
				_basepath = DEFAULT_CACHE_PATH;
			}
		}
		
		private function get stream():FileStream
		{
			return _stream ||= new FileStream();
		}

		private function get file():File
		{
			return _file ||= new File();
		}

		private function get loader():URLLoader
		{
			if (!_loader)
			{
				_loader = new URLLoader();
				_loader.dataFormat = URLLoaderDataFormat.BINARY;
			}
			return _loader;
		}

		private function get request():URLRequest
		{
			return _request ||= new URLRequest();
		}
		
		private function get hasRequestsToProcess():Boolean
		{
			return queue.length > 0;
		}
		
		private function get isLoaderBusy():Boolean
		{
			return loader && loader.hasEventListener(Event.COMPLETE);
		}
		
		private function getCacheFileFor(url:String):File
		{
			var hash:String = MD5.hash(url);
			file.url = _basepath + File.separator + hash;
			_file.canonicalize();
			return _file;
		}
		
		public function getImageByURL(url:String):String
		{
			var cacheFile:File = getCacheFileFor(url);
			if (cacheFile.exists)
			{
				return cacheFile.url;
			}
			else
			{
				addImageToCache(url);
				return url;
			}
			
		}
		
		private  function addImageToCache(url:String):void
		{
			if (queue.indexOf(url) == -1)
			{
				queue.push(url);
				processNext();
			}
		}
		
		private function processNext():void
		{
			if (!hasRequestsToProcess || isLoaderBusy) return;
			
			request.url = queue[0] || "";
			
			loader.addEventListener(Event.COMPLETE, loadCompleteHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, loadErrorHandler);
			loader.load(request);
		}
		
		private function storeToDisk(url:String, bytes:ByteArray):void
		{
			var cacheFile:File = getCacheFileFor(url);
			
			stream.open(cacheFile, FileMode.WRITE);
			stream.writeBytes(bytes);
			stream.close();
		}
		
		private function loadCompleteHandler(event:Event):void
		{
			loader.removeEventListener(Event.COMPLETE, loadCompleteHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, loadErrorHandler);
			
			var url:String = queue.shift() as String;
			var data:ByteArray = loader.data as ByteArray;
			
			try
			{
				storeToDisk(url, data);
			}
			catch(error:Error)
			{
				addImageToCache(url);
			}
			finally
			{
				processNext();
			}
		}
		
		protected function loadErrorHandler(event:ErrorEvent):void
		{
			loader.removeEventListener(Event.COMPLETE, loadCompleteHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, loadErrorHandler);
			
			queue.shift();
			
			processNext();
		}
	}
}