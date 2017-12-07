package spark.components
{
	import spark.events.LinkElementFocusEvent;
	
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.text.engine.TextLine;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.Dictionary;
	
	import flashx.textLayout.compose.IFlowComposer;
	import flashx.textLayout.compose.TextFlowLine;
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.LinkState;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.events.FlowElementMouseEvent;
	import flashx.textLayout.events.SelectionEvent;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.tlf_internal;
	
	import mx.core.mx_internal;
	
	import spark.components.RichEditableText;
	
	use namespace mx_internal;
	use namespace tlf_internal;
	
	//--------------------------------------
	//  Events
	//--------------------------------------
	
	/**
	 *  Dispached after the internal focus moves to a <code>LinkElement</code>.
	 *
	 *  @eventType axm.view.events.LinkElementFocusEvent
	 *  
	 *  @langversion 3.0
	 *  @playerversion Flash 10
	 *  @playerversion AIR 1.5
	 *  @productversion Flex 4
	 */
	[Event(name="linkFocusIn", type="spark.events.LinkElementFocusEvent")]
	
	/**
	 *  Dispached after the internal focus moves away from a <code>LinkElement</code>.
	 *
	 *  @eventType axm.view.events.LinkElementFocusEvent
	 *  
	 *  @langversion 3.0
	 *  @playerversion Flash 10
	 *  @playerversion AIR 1.5
	 *  @productversion Flex 4
	 */
	[Event(name="linkFocusOut", type="spark.events.LinkElementFocusEvent")]
	
	//--------------------------------------
	//  Other metadata
	//--------------------------------------
	
	[AccessibilityClass(implementation="spark.accessibility.RichEditableText2AccImpl")]
	
	public class RichEditableText2 extends RichEditableText implements IEventDispatcher
	{
		//--------------------------------------------------------------------------
		//
		//  Class mixins
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  @private
		 *  Placeholder for mixin by RichEditableTextAccImpl.
		 */
		mx_internal static var createAccessibilityImplementation:Function;
		
		public function RichEditableText2()
		{
			super();
			
			textContainerManager.addEventListener(SelectionEvent.SELECTION_CHANGE,
				textContainerManager_selectionChangeHandler, false, 0, true);
			textContainerManager.addEventListener(FlowElementMouseEvent.MOUSE_DOWN,
				textContainerManager_clickHandler, false, 0, true);
		}
		
		//--------------------------------------------------------------------------
		//
		//  Variables
		//
		//--------------------------------------------------------------------------
		
		public var focusedLinkElement:LinkElement;
		
		mx_internal var accessibleElements:Vector.<FlowElement>;
		
		mx_internal var accessibleElementsDict:Dictionary;
		
		mx_internal var linkElements:Vector.<LinkElement>;
		
		mx_internal var caretIndex:int = -1;
		
		mx_internal var caretChanged:Boolean = false;
		
		mx_internal var _manageInternalFocus:Boolean = false;
		mx_internal function get manageInternalFocus():Boolean
		{
			return _manageInternalFocus;
		}
		mx_internal function set manageInternalFocus(value:Boolean):void
		{
			if (value==_manageInternalFocus) return;
			_manageInternalFocus = value;
			if (stage)
			{
				if (_manageInternalFocus)
				{
					stage.addEventListener(FocusEvent.MOUSE_FOCUS_CHANGE,stage_mouseFocusChangeHandler, false, 0, true);
					stage.addEventListener(Event.DEACTIVATE,stage_deactivateHandler, false, 0, true);
				} else
				{
					stage.removeEventListener(FocusEvent.MOUSE_FOCUS_CHANGE,stage_mouseFocusChangeHandler);
					stage.removeEventListener(Event.DEACTIVATE,stage_deactivateHandler);
				}
			}
		}
		
		//--------------------------------------------------------------------------
		//
		//  Overridden Methods: UIComponent
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  @private
		 */
		override protected function initializeAccessibility():void
		{
			if (RichEditableText2.createAccessibilityImplementation != null)
				RichEditableText2.createAccessibilityImplementation(this);
		}
		
		private var _cachedText:String;
		override protected function commitProperties():void
		{			
			super.commitProperties();
			
			if (_cachedText != text)
			{	
				_cachedText = text;
				buildAccessibleElements(textFlow);
			}
			
			// Updating the text programatically removes all child TextLine elements
			// before rebuilding the TextFlow, effectively removing all visual elements
			// from the display list. This causes any accessibilityImplementation that
			// was assigned to the component to be removed. The following line restores
			// the accessibilityImplementation if it no longer exists. See SDK-31905
			if (!accessibilityImplementation)
				initializeAccessibility();
		}
		
		
		private function buildAccessibleElements(source:TextFlow):void
		{
			accessibleElements = new Vector.<FlowElement>();
			accessibleElementsDict = new Dictionary();
			linkElements = new Vector.<LinkElement>();
			
			var leaf:FlowLeafElement = source.getFirstLeaf();
			while (leaf)
			{
				var p:ParagraphElement = leaf.getParagraph();
				while (true)
				{	
					var linkElement:LinkElement = leaf.getParentByType(LinkElement) as LinkElement;
					if (linkElement)
					{
						accessibleElements.push(linkElement);
						linkElements.push(linkElement);
						accessibleElementsDict[linkElement] = accessibleElements.length-1;
						linkElement.removeEventListener(FlowElementMouseEvent.ROLL_OVER, handleFlowElementMouseEvent);
						linkElement.removeEventListener(FlowElementMouseEvent.ROLL_OUT, handleFlowElementMouseEvent);
						linkElement.removeEventListener(FlowElementMouseEvent.MOUSE_MOVE, handleFlowElementMouseEvent);
						linkElement.removeEventListener(FlowElementMouseEvent.CLICK, handleFlowElementMouseEvent);
						linkElement.addEventListener(FlowElementMouseEvent.ROLL_OVER, handleFlowElementMouseEvent, false, 0, true);
						linkElement.addEventListener(FlowElementMouseEvent.ROLL_OUT, handleFlowElementMouseEvent, false, 0, true);
						linkElement.addEventListener(FlowElementMouseEvent.MOUSE_MOVE, handleFlowElementMouseEvent, false, 0, true);
						linkElement.addEventListener(FlowElementMouseEvent.CLICK, handleFlowElementMouseEvent, false, 0, true);
					} else {
						accessibleElements.push(leaf);
						accessibleElementsDict[leaf] = accessibleElements.length-1;
					}
					
					leaf = leaf.getNextLeaf(p);
					if (!leaf)	break;
				}
				leaf = p.getLastLeaf().getNextLeaf();
			}
		}
		
		override public function drawFocus(isFocused:Boolean):void
		{
			if (focusedLinkElement)
			{
				updateLinkElementStates();
				super.drawFocus(editable);
				
				
			} else
			{
				super.drawFocus(isFocused);
			}
		}
		
		protected function updateLinkElementStates():void
		{
			for(var i:uint = 0; i<linkElements.length; i++)
			{
				var linkElement:LinkElement = linkElements[i];
				var state:String = (linkElement==focusedLinkElement && getFocus()==this)
					? LinkState.HOVER
					: LinkState.LINK;
				var lastOne:Boolean =  (i==linkElements.length-1);
				setLinkElementState(linkElement, state, lastOne);
			}
		}
		
		protected function setLinkElementState(linkElement:LinkElement, state:String, lastOne:Boolean=false):void
		{
			if (linkElement.linkState == state) return;
			var oldCharAttrs:ITextLayoutFormat = linkElement.effectiveLinkElementTextLayoutFormat;
			linkElement.chgLinkState(state);
			var newCharAttrs:ITextLayoutFormat = linkElement.effectiveLinkElementTextLayoutFormat;
			if (!(TextLayoutFormat.isEqual(oldCharAttrs, newCharAttrs)))
			{
				linkElement.formatChanged(true);
				
				trace(linkElement+" "+accessibleElementsDict[linkElement]+" setLinkElementState : "+linkElement.linkState+" expected textDecoration: "+newCharAttrs.textDecoration);
				
				if(!lastOne) return; 
				var tf:TextFlow = linkElement.getTextFlow();
				if (tf && tf.flowComposer)
				{
					tf.flowComposer.updateAllControllers();
				}
			}
		}
		
		protected function scrollToFlowElement(flowElement:FlowElement,shiftKey:Boolean=false):void
		{
			if (!flowElement) return;
						
			var containerController:ContainerController = textFlow.flowComposer.getControllerAt(0);
			var lastVisibleLine:TextFlowLine = containerController.getLastVisibleLine();
			var lastVisibleIndex:uint = lastVisibleLine.absoluteStart + lastVisibleLine.textLength;
			
			var start:int = flowElement.getAbsoluteStart();
			var end:int = start + flowElement.textLength;
			if (shiftKey && end<=lastVisibleIndex) 
				scrollToRange(start, start);
			else
				scrollToRange(end, end);
			
			if((selectionAnchorPosition<start || selectionAnchorPosition>end)
				&& (selectionActivePosition<start || selectionActivePosition>end))
			{
				selectRange(start,start);
			}
		}
		
		public function getElementBounds(flowElement:FlowElement):Rectangle
		{			
			var start:int,
				end:int,
				current:int,
				rect:Rectangle,
				nextRect:Rectangle,
				point:Point,
				textFlowLine:TextFlowLine,  
				textLine:TextLine,
				lineStart:int,
				posInLine:int,
				tf:TextFlow,
				flowComposer:IFlowComposer,
				containerController:ContainerController,
				lastVisibleLine:TextFlowLine,
				lastVisibleIndex:int; 
			
			tf = flowElement.getTextFlow();
			if (!tf) return null;
			flowComposer = tf.flowComposer;
			if (!flowComposer) return null;
			containerController = flowComposer.getControllerAt(0);
			if (!containerController) return null;
			lastVisibleLine = containerController.getLastVisibleLine();
			lastVisibleIndex = lastVisibleLine.absoluteStart + lastVisibleLine.textLength;
			
			current = start = flowElement.getAbsoluteStart();
			end = Math.min(lastVisibleIndex,(start + flowElement.textLength));
			
			var containerPoint:Point = localToGlobal(new Point(x,y));
			
			while(current>=containerController.absoluteStart && current<end)
			{
				textFlowLine = tf.flowComposer.findLineAtPosition(current);
				textLine = textFlowLine.getTextLine(true); 
				if (textLine)
				{
					if (!rect) 
						rect = new Rectangle();
					
					lineStart = textFlowLine.absoluteStart;
					
					posInLine = current - lineStart;
					
					nextRect = textLine.getAtomBounds(posInLine);
					if (nextRect)
					{
						point = new Point(nextRect.x, nextRect.y);
						if (textLine.stage)
						{
							point = textLine.localToGlobal(point);
						} else
						{
							// If the textLine is not rendered to the stage, 
							// which is the case when it is scrolled out of view,
							// adjust the origin relative to the RichEditableText2 control. 
							point.x += containerPoint.x;
							point.y += containerPoint.y;
						}
						
						// adjust the origin to account for scroll position
						nextRect.x = point.x-containerController.horizontalScrollPosition;
						nextRect.y = point.y-containerController.verticalScrollPosition+textLine.descent;
						
						rect = rect.union(nextRect);
					}
				}
				
				current++;
			}
			if (rect)
			{
				point = globalToLocal(new Point(rect.x,rect.y));
				rect.x = point.x;
				rect.y = point.y;
			}
			return rect || null;
		}
		
		//--------------------------------------------------------------------------
		//
		//  Event handlers
		//
		//--------------------------------------------------------------------------
		
		override mx_internal function keyDownHandler(event:KeyboardEvent):void
		{
			if (linkElements.length>0)
			{
				switch (event.keyCode)
				{
					case Keyboard.TAB:
					{
						break;
					}
					case Keyboard.SPACE:
					case Keyboard.ENTER:
					{	
						if (focusedLinkElement != null 
							&& (!editable || event.ctrlKey))
								triggerLinkElementClick(focusedLinkElement);
						break;
					}
				}
			}
			
			super.mx_internal::keyDownHandler(event);
		}
		
		
		override protected function keyDownHandler(event:KeyboardEvent):void
		{
			if (linkElements.length>0)
			{
				switch (event.keyCode)
				{
					case Keyboard.TAB:
					{
						if (editable && !textFlow.configuration.manageTabKey) 
						{
							event.stopImmediatePropagation();
							super.mx_internal::keyDownHandler(event);
						} else {
							super.protected::keyDownHandler(event);
						}
						return;
					}
					case Keyboard.SPACE:
					case Keyboard.ENTER:
					{	
						if (focusedLinkElement != null 
							&& (!editable || event.ctrlKey))
							triggerLinkElementClick(focusedLinkElement);
						break;
					}
				}
			}
			
			super.protected::keyDownHandler(event);
		}
		
		mx_internal function keyFocusChangeHandler(event:FocusEvent):void
		{	
			if (linkElements.length==0 || accessibleElements.length==0) return;
			
			var relatedElement:FlowElement = (caretIndex>=0) ? accessibleElements[caretIndex] : null;
			
			if (caretIndex == -1)
			{
				if (!event.relatedObject 
					|| event.relatedObject==this)
				{
					calculateCaretIndexAndFocusedLinkElement();
				} else if (linkElements.length)
				{
					focusedLinkElement = (event.shiftKey) ? linkElements[linkElements.length-1] : linkElements[0];
					caretIndex = accessibleElementsDict[focusedLinkElement];
				} else
				{
					focusedLinkElement = null;
					caretIndex = (event.shiftKey) ? accessibleElements.length-1 : 0;
				}
				
				caretChanged = (caretIndex>=0);
				manageInternalFocus = (editable) ? false : true;
				
				if (getFocus()==this) drawFocus(true);
				
			} else
			{
				var dir:int = (event.shiftKey) ? -1 : 1;
				var linkIndex:int = -1;
				if (focusedLinkElement)
				{
					linkIndex = dir + linkElements.indexOf(focusedLinkElement);
					if (linkIndex>=0 && linkIndex<linkElements.length)
					{
						focusedLinkElement = linkElements[linkIndex];
						caretIndex = accessibleElementsDict[focusedLinkElement];
						caretChanged = true;
					} else {
						focusedLinkElement = null;
						caretChanged = false;
					}
				} else
				{
					var caretPos:int = caretIndex + dir;
					while(caretPos>=0 && caretPos<accessibleElements.length)
					{
						if (accessibleElements[caretPos] is LinkElement)
						{
							focusedLinkElement = accessibleElements[caretPos] as LinkElement;
							caretIndex = caretPos;
							caretChanged = true;
							break;
						}
						caretPos += dir;
					}
				}
			}
			
			if (caretChanged)
			{	
				event.preventDefault();
				scrollToFlowElement(focusedLinkElement,event.shiftKey);
				caretChanged = false;	
			} else
			{	
				focusedLinkElement = null;
				caretIndex = -1;
				caretChanged = false;
				manageInternalFocus = false;
				
				if (focusManager)
					focusManager.defaultButtonEnabled = true;
			}
			
			updateLinkElementStates();
			
			if (relatedElement && relatedElement is LinkElement)
			{
				var focusOutEvent:LinkElementFocusEvent = new LinkElementFocusEvent(LinkElementFocusEvent.LINK_FOCUS_OUT, relatedElement as LinkElement);
				focusOutEvent.relatedElement = (focusedLinkElement) 
												? focusedLinkElement 
												: ((caretIndex!=-1)
													? accessibleElements[caretIndex] 
													: null);
				focusOutEvent.relatedObject = (focusedLinkElement) ? null : event.relatedObject;
				dispatchEvent(focusOutEvent);
			}
			
			if (focusedLinkElement)
			{
				var focusInEvent:LinkElementFocusEvent = new LinkElementFocusEvent(LinkElementFocusEvent.LINK_FOCUS_IN, focusedLinkElement);
				focusInEvent.relatedElement = (relatedElement) ? relatedElement : null;
				focusInEvent.relatedObject = (relatedElement) ? null : event.relatedObject;
				dispatchEvent(focusInEvent);
			}
		}
		
		public function triggerLinkElementClick(linkElement:LinkElement):void
		{
			var href:String = linkElement.href;
			var target:String = (linkElement.target || "");
			if (href != null)
			{
				if ((href.length > 6) && (href.substr(0, 6) == "event:"))
				{
					dispatchFlowElementMouseEvent(href.substring(6, href.length), linkElement);
				} 
				else 
				{
					var u:URLRequest = new URLRequest(encodeURI(href));
					flash.net.navigateToURL(u, target);
				}
			}
		}
	  
		private function dispatchFlowElementMouseEvent(type:String, flowElement:FlowElement):Boolean
		{	
			var locallyListening:Boolean = flowElement.hasActiveEventMirror();
			var textFlow:TextFlow = flowElement.getTextFlow();
			var textFlowListening:Boolean = false;
			if (textFlow)
				textFlowListening = textFlow.hasEventListener(type);
			
			if (!locallyListening && !textFlowListening)
				return false;
			
			var event:FlowElementMouseEvent = new FlowElementMouseEvent(type, false, true, flowElement, new MouseEvent(MouseEvent.CLICK));
			if (locallyListening)
			{
				flowElement.getEventMirror().dispatchEvent(event);
				if (event.isDefaultPrevented())
					return true;
			}
			if (textFlowListening)
			{
				textFlow.dispatchEvent(event);
				if (event.isDefaultPrevented())
					return true;
			}
			return false;
		}
		
		/**
		 *  @private
		 *  RichEditableTextContainerManager overrides focusInHandler and calls
		 *  this before executing its own focusInHandler.
		 */
		override mx_internal function focusInHandler(event:FocusEvent):void
		{
			if (linkElements.length==0)
			{
				super.mx_internal::focusInHandler(event);
				return;
			}
			
			manageInternalFocus = (editable) ? false : true;
			addEventListener(FocusEvent.KEY_FOCUS_CHANGE,keyFocusChangeHandler, false, 0, true);

			var cachedCaretIndex:int = caretIndex;
			try
			{
				if (!event.relatedObject 
					|| event.relatedObject==this)
				{
					calculateCaretIndexAndFocusedLinkElement(focusedLinkElement);
				} else if (linkElements.length) {
					focusedLinkElement = (event.shiftKey) ? linkElements[linkElements.length-1] : linkElements[0];
					caretIndex = accessibleElementsDict[focusedLinkElement];
				} else {
					focusedLinkElement = null;
					caretIndex = (event.shiftKey) ? accessibleElements.length-1 : 0;
				}
				
				if (focusedLinkElement)
					scrollToFlowElement(focusedLinkElement, event.shiftKey);
				
				if (focusManager.defaultButton)
					focusManager.defaultButtonEnabled = (focusedLinkElement) ? false : focusManager.defaultButtonEnabled;
			} catch(error:Error)
			{
				trace(error.toString());
			}
			
			super.mx_internal::focusInHandler(event);
			
			if (focusedLinkElement && (cachedCaretIndex != caretIndex))
			{
				var focusInEvent:LinkElementFocusEvent = new LinkElementFocusEvent(LinkElementFocusEvent.LINK_FOCUS_IN, focusedLinkElement);
				focusInEvent.relatedElement = null;
				focusInEvent.relatedObject = event.relatedObject;
				dispatchEvent(focusInEvent);
			}
			
		}
		
		override protected function focusInHandler(event:FocusEvent):void
		{
			if (linkElements.length>0)
			{
				mx_internal::focusInHandler(event);
			} else
			{
				super.protected::focusInHandler(event);
			}
		}
		
		override protected function focusOutHandler(event:FocusEvent):void
		{
			manageInternalFocus = false;
			removeEventListener(FocusEvent.KEY_FOCUS_CHANGE,keyFocusChangeHandler);
			if (linkElements.length == 0) 
			{
				super.protected::focusOutHandler(event);
				return;
			}
			super.mx_internal::focusOutHandler(event);
		}
		
		private function stage_mouseFocusChangeHandler(event:FocusEvent):void
		{
			if (event.relatedObject!=this)
			{
				if (linkElements.length>0 
					&& event.relatedObject 
					&& event.relatedObject.parent 
					&& event.relatedObject.parent == textContainerManager.container) return;
				removeEventListener(FocusEvent.KEY_FOCUS_CHANGE,keyFocusChangeHandler);
				caretIndex = -1;
				focusedLinkElement = null;
				manageInternalFocus = false;
				updateLinkElementStates();
			}
		}
		
		private function stage_activateHandler(event:Event):void
		{
			event.target.removeEventListener(event.type, arguments.callee);
			event.target.addEventListener(Event.DEACTIVATE, stage_deactivateHandler);
			manageInternalFocus = ((caretIndex!=-1 || focusedLinkElement) && getFocus()==this) ? true : false;
		}
		
		private function stage_deactivateHandler(event:Event):void
		{
			event.target.removeEventListener(event.type, arguments.callee);
			event.target.addEventListener(Event.ACTIVATE, stage_activateHandler);
			manageInternalFocus = false;
		}
		
		/**
		 *  @private
		 *  Called when the TextContainerManager dispatches a 'selectionChange' event.
		 */
		private function textContainerManager_selectionChangeHandler(event:SelectionEvent):void
		{
			calculateCaretIndexAndFocusedLinkElement();				
		}
		
		private function handleFlowElementMouseEvent(event:FlowElementMouseEvent):void
		{
			if (!(event.flowElement is LinkElement)) return;
			if (event.type == FlowElementMouseEvent.CLICK 
				&& event.flowElement is LinkElement)
			{
				if (getFocus()!=this)
					setFocus();
				
				calculateCaretIndexAndFocusedLinkElement(event.flowElement);
				
				Mouse.cursor = MouseCursor.AUTO;
				Mouse.hide();
				Mouse.show();
			}
			
			if (event.flowElement == focusedLinkElement)
			{
				callLater(updateLinkElementStates);
			}
		}
		
		/**
		 *  @private
		 *  Called when the TextContainerManager dispatches a 'mouseDown' event.
		 */
		private function textContainerManager_clickHandler(event:FlowElementMouseEvent):void
		{
			calculateCaretIndexAndFocusedLinkElement(event.flowElement);
		}
				
		private function calculateCaretIndexAndFocusedLinkElement(flowElement:FlowElement=null):void
		{	
			if (caretChanged) return;
			
			var leaf:FlowLeafElement = textFlow.findLeaf(selectionActivePosition) as FlowLeafElement;
			if (flowElement!=null)
			{
				focusedLinkElement = flowElement as LinkElement;
			} else if (leaf != null) {
				focusedLinkElement = leaf.getParentByType(LinkElement) as LinkElement;
			}
			var key:FlowElement = (focusedLinkElement || leaf);
			if (key)
			{
				caretIndex = accessibleElementsDict[key];
				// "calculateCaretIndexAndFocusedLinkElement :\t"+caretIndex+ "\t"+key+"\t"+key.getText());
			} else {
				caretIndex = -1;
				focusedLinkElement = null;
			}
			
			updateLinkElementStates();
		}
	}
}