package spark.events
{
	import flash.display.InteractiveObject;
	import flash.events.FocusEvent;
	
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.LinkElement;
	
	public class LinkElementFocusEvent extends FocusEvent
	{
		public static const LINK_FOCUS_IN:String = "linkFocusIn";
		public static const LINK_FOCUS_OUT:String = "linkFocusOut";
		
		private var _linkElement:LinkElement;
		public function get linkElement():LinkElement
		{
			return _linkElement;
		}
		
		public function set linkElement(value:LinkElement):void
		{
			_linkElement = value;
		}
		
		private var _relatedElement:FlowElement;
		public function get relatedElement():FlowElement
		{
			return _relatedElement;
		}
		
		public function set relatedElement(value:FlowElement):void
		{
			_relatedElement = value;
		}
		
		public function LinkElementFocusEvent(type:String, 
											  linkElement:LinkElement,
											  relatedElement:FlowElement=null,
											  bubbles:Boolean=true, 
											  cancelable:Boolean=false, 
											  relatedObject:InteractiveObject=null, 
											  shiftKey:Boolean=false, 
											  keyCode:uint=0)
		{
			super(type, bubbles, cancelable, relatedObject, shiftKey, keyCode);
			_linkElement = linkElement;
			_relatedElement = relatedElement;
		}
		
		//Override toString
		override public function toString():String
		{
			return formatToString("LinkElementFocusEvent", "type", "bubbles", "cancelable", "eventPhase", "linkElement", "relatedElement", "relatedObject", "shiftKey", "keyCode");
		}

	}
}