////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2003-2007 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package mx.managers
{
    
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.InteractiveObject;
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.FocusEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.system.Capabilities;
    import flash.system.IME;
    import flash.text.TextField;
    import flash.ui.Keyboard;
    
    import mx.core.FlexSprite;
    import mx.core.IButton;
    import mx.core.IChildList;
    import mx.core.IIMESupport;
    import mx.core.IRawChildrenContainer;
    import mx.core.ISWFLoader;
    import mx.core.IUIComponent;
    import mx.core.UIComponent;
    import mx.core.mx_internal;
    import mx.events.FlexEvent;
    
    use namespace mx_internal;
    
    /** 
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public class ReadOrderManager extends EventDispatcher
    {
        // include "../core/Version.as";
        
        //--------------------------------------------------------------------------
        //
        //  Class constants
        //
        //--------------------------------------------------------------------------
        
        /**
         * @private
         * 
         * Default value of parameter, ignore. 
         */
        private static const FROM_INDEX_UNSPECIFIED:int = -2;
        
        //--------------------------------------------------------------------------
        //
        //  Class variables
        //
        //--------------------------------------------------------------------------
        
        /**
         * @private
         * 
         * Place to hook in additional classes
         */
        public static var mixins:Array;
        
        //--------------------------------------------------------------------------
        //
        //  Constructor
        //
        //--------------------------------------------------------------------------
        
        /**
         *  Constructor.
         *
         *  <p>A FocusManager manages the focus within the children of an IFocusManagerContainer.
         *  It installs itself in the IFocusManagerContainer during execution
         *  of the constructor.</p>
         *
         *  @param container An IFocusManagerContainer that hosts the FocusManager.
         *
         *  @param popup If <code>true</code>, indicates that the container
         *  is a popup component and not the main application.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public function ReadOrderManager(container:DisplayObjectContainer)
        {
            super();
            
            _form = container;
            
            readableObjects = [];
            
            addReadables(DisplayObject(container));
            
            // Listen to the stage so we know when the root application is loaded.
            container.addEventListener(Event.ADDED, addedHandler);
            container.addEventListener(Event.REMOVED, removedHandler);
        }
        
        //--------------------------------------------------------------------------
        //
        //  Variables
        //
        //--------------------------------------------------------------------------
        
        private var LARGE_TAB_INDEX:int = 99999;
        
        mx_internal var calculateCandidates:Boolean = true;
        
        /**
         *  @private
         *  We track whether we've been last activated or saw a TAB
         *  This is used in browser tab management
         */
        mx_internal var lastAction:String;
        
        /**
         *  @private
         *  Total set of all objects that can be included in the read order
         *  but might be disabled or invisible.
         */
        mx_internal var readableObjects:Array;
        
        /**
         *  @private
         *  Filtered set of objects that can be included in the read order right now.
         */
        private var readableCandidates:Array;
        
        /**
         *  @private
         */
        private var activated:Boolean;
        
        //--------------------------------------------------------------------------
        //
        //  Properties
        //
        //--------------------------------------------------------------------------
        
        //----------------------------------
        //  form
        //----------------------------------
        
        /**
         *  @private
         *  Storage for the form property.
         */
        private var _form:DisplayObjectContainer;
        
        /**
         *  @private
         *  The form is the property where we store the DisplayObjectContainer
         *  that hosts this ReadOrderManager.
         */
        mx_internal function get form():DisplayObjectContainer
        {
            return _form;
        }
        
        /**
         *  @private
         */
        mx_internal function set form (value:DisplayObjectContainer):void
        {
            _form = value;
        }
        
        //----------------------------------
        //  nextTabIndex
        //----------------------------------
        
        /**
         *  @inheritDoc
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        public function get nextTabIndex():int
        {
            return getMaxTabIndex() + 1;
        }
        
        /**
         *  Gets the highest tab index currently used in this ReadOrderManager.
         *
         *  @return Highest tab index currently used.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        private function getMaxTabIndex():int
        {
            var z:Number = 0;
            
            var n:int = readableObjects.length;
            for (var i:int = 0; i < n; i++)
            {
                var t:Number = readableObjects[i].tabIndex;
                if (!isNaN(t))
                    z = Math.max(z, t);
            }
            
            return z;
        }
        
        //--------------------------------------------------------------------------
        //
        //  Methods
        //
        //--------------------------------------------------------------------------
        
        /**
         *  @private
         *  Returns true if p is a parent of o.
         */
        private function isParent(p:DisplayObjectContainer, o:DisplayObject):Boolean
        {
            if (p == o)
                return false;
            
            if (p is IRawChildrenContainer)
                return IRawChildrenContainer(p).rawChildren.contains(o);
            
            return p.contains(o);
        }
        
        private function isEnabledAndVisible(o:DisplayObject):Boolean
        {
            var formParent:DisplayObjectContainer = DisplayObjectContainer(form);
            
            while (o != formParent)
            {
                if (o is IUIComponent)
                    if (!IUIComponent(o).enabled)
                        return false;
                
                /*if (o is IVisualElement)
                    if (IVisualElement(o).designLayer && !IVisualElement(o).designLayer.effectiveVisibility)
                        return false;
                */
                if (!o.visible) 
                    return false;
                o = o.parent;
                
                // if no parent, then not on display list
                if (!o)
                    return false;
            }
            return true;
        }
        
        /**
         *  @private
         */
        private function sortByTabIndex(a:InteractiveObject, b:InteractiveObject):int
        {
            var aa:int = a.tabIndex;
            var bb:int = b.tabIndex;
            
            if (aa == -1)
                aa = int.MAX_VALUE;
            if (bb == -1)
                bb = int.MAX_VALUE;
            
            return (aa > bb ? 1 :
                aa < bb ? -1 : sortByDepth(DisplayObject(a), DisplayObject(b)));
        }
        
        /**
         *  @private
         */
        private function sortReadableObjectsTabIndex():void
        {
            // trace("ReadableObjectsTabIndex");
            
            readableCandidates = [];
            
            var n:int = readableObjects.length;
            for (var i:int = 0; i < n; i++)
            {
                var c:InteractiveObject = readableObjects[i] as InteractiveObject;
                if ((c && c.tabIndex && !isNaN(Number(c.tabIndex))) ||
                    readableObjects[i] is ISWFLoader)
                {
                    // if we get here, it is a candidate
                    readableCandidates.push(readableObjects[i]);
                }
            }
            
            readableCandidates.sort(sortByTabIndex);
        }
        
        /**
         *  @private
         */
        private function sortByDepth(aa:DisplayObject, bb:DisplayObject):Number
        {
            var val1:String = "";
            var val2:String = "";
            var index:int;
            var tmp:String;
            var tmp2:String;
            var zeros:String = "0000";
            
            var a:DisplayObject = DisplayObject(aa);
            var b:DisplayObject = DisplayObject(bb);
            
            // TODO (egreenfi):  If a component lives inside of a group, we care about not its display object index, but
            // its index within the group. See SDK-25144
            
            while (a != DisplayObject(form) && a.parent)
            {
                index = getChildIndex(a.parent, a);
                tmp = index.toString(16);
                if (tmp.length < 4)
                {
                    tmp2 = zeros.substring(0, 4 - tmp.length) + tmp;
                }
                val1 = tmp2 + val1;
                a = a.parent;
            }
            
            while (b != DisplayObject(form) && b.parent)
            {
                index = getChildIndex(b.parent, b);
                tmp = index.toString(16);
                if (tmp.length < 4)
                {
                    tmp2 = zeros.substring(0, 4 - tmp.length) + tmp;
                }
                val2 = tmp2 + val2;
                b = b.parent;
            }
            
            return val1 > val2 ? 1 : val1 < val2 ? -1 : 0;
        }
        
        private function getChildIndex(parent:DisplayObjectContainer, child:DisplayObject):int
        {
            try 
            {
                return parent.getChildIndex(child);
            }
            catch(e:Error)
            {
                if (parent is IRawChildrenContainer)
                    return IRawChildrenContainer(parent).rawChildren.getChildIndex(child);
                throw e;
            }
            throw new Error("ReadOrderManager.getChildIndex failed");   // shouldn't ever get here
        }
        
        /**
         *  @private
         *  Calculate what focusableObjects are valid tab candidates.
         */
        private function sortReadableObjects():void
        {
            // trace("ReadableObjects " + readableObjects.length.toString());
            readableCandidates = [];
            
            var n:int = readableObjects.length;
            for (var i:int = 0; i < n; i++)
            {
                var c:InteractiveObject = readableObjects[i];
                // trace("  " + c);
                if (c.tabIndex && !isNaN(Number(c.tabIndex)) && c.tabIndex > 0)
                {
                    sortReadableObjectsTabIndex();
                    return;
                }
                readableCandidates.push(c);
            }
            
            readableCandidates.sort(sortByDepth);
        }
        
        /**
         *  @private
         *  Do a tree walk and add all children you can find.
         */
        mx_internal function addReadables(o:DisplayObject, skipTopLevel:Boolean = false):void
        {
            trace(">>addReadables " + o);
            var io:InteractiveObject = o as InteractiveObject;
            if (io 
                && !skipTopLevel
                && io.parent.tabChildren)
            {
                if (readableObjects.indexOf(o) == -1)
                {
                    readableObjects.push(o);
                    calculateCandidates = true;
                    trace("RM added " + o);
                }
                if (o.hasOwnProperty("label"))
                {
                    trace("!!!!!!!!! label: " + o["label"] + " - item " + getMaxTabIndex());
                }
                else if (o.hasOwnProperty("text"))
                {
                    trace("!!!!!!!!! text: " + o["text"] + " - item " + getMaxTabIndex());
                }
            }
            
            if (o is DisplayObjectContainer && DisplayObjectContainer(o).tabChildren)
            {
                var doc:DisplayObjectContainer = DisplayObjectContainer(o);
                
                if (o is IRawChildrenContainer)
                {
                    trace("using view rawChildren");
                    var rawChildren:IChildList = IRawChildrenContainer(o).rawChildren;
                    // recursively visit and add children of components
                    // we don't do this for containers because we get individual
                    // adds for the individual children
                    var i:int;
                    for (i = 0; i < rawChildren.numChildren; i++)
                    {
                        try
                        {
                            addReadables(rawChildren.getChildAt(i));
                        }
                        catch(error:SecurityError)
                        {
                            // Ignore this child if we can't access it
                            trace("addFocusables: ignoring security error getting child from rawChildren: " + error);
                        }
                    }
                    
                }
                else
                {
                    trace("using container's children");
                    // recursively visit and add children of components
                    // we don't do this for containers because we get individual
                    // adds for the individual children
                    for (i = 0; i < doc.numChildren; i++)
                    {
                        try
                        {
                            addReadables(doc.getChildAt(i));
                        }
                        catch(error:SecurityError)
                        {
                            // Ignore this child if we can't access it
                            trace("addFocusables: ignoring security error getting child at document." + error);
                        }
                    }
                }
            }
            trace("<<addReadables " + o);
        }
        
        /**
         *  Returns a String representation of the component hosting the ReadOrderManager object, 
         *  with the String <code>".readOrderManager"</code> appended to the end of the String.
         *
         *  @return Returns a String representation of the component hosting the ReadOrderManager object, 
         *  with the String <code>".readOrderManager"</code> appended to the end of the String.
         *  
         *  @langversion 3.0
         *  @playerversion Flash 9
         *  @playerversion AIR 1.1
         *  @productversion Flex 3
         */
        override public function toString():String
        {
            return Object(form).toString() + ".readOrderManager";
        }
        
        public function createReadOrder():void
        {
            updateReadingOrder(true);
        }
        
        public function destroyReadOrder():void
        {
            updateReadingOrder(false);
        }
        
        private function updateReadingOrder(fix:Boolean):void
        {
            for (var i:uint = 0; i < readableObjects.length; i++) 
            {
                try {
                    var obj:InteractiveObject = readableObjects[i] as InteractiveObject;
                    obj.tabIndex = fix ? i + 1 : -1;
                }
                catch (e:Error) {}
            }
        }
        
        //--------------------------------------------------------------------------
        //
        //  Event handlers
        //
        //--------------------------------------------------------------------------
        
        /**
         *  @private
         *  Listen for children being added
         *  and see if they are focus candidates.
         */
        private function addedHandler(event:Event):void
        {
            var target:DisplayObject = DisplayObject(event.target);
            
            // trace("FM: addedHandler: got added for " + target);
            
            // if it is truly parented, add it, otherwise it will get added when the top of the tree
            // gets parented.
            if (target.stage)
            {
                // trace("FM: addedHandler: adding focusables");
                addReadables(DisplayObject(event.target));
            }
        }
        
        /**
         *  @private
         *  Listen for children being removed.
         */
        private function removedHandler(event:Event):void
        {
            var i:int;
            var o:DisplayObject = DisplayObject(event.target);
            
            if (o is InteractiveObject)
            {
                for (i = 0; i < readableObjects.length; i++)
                {
                    if (o == readableObjects[i])
                    {
                        readableObjects.splice(i, 1);
                        readableCandidates = [];
                        calculateCandidates = true;                 
                        break;
                    }
                }
            }
            removeReadables(o, false);
        }
        
        /**
         *  @private
         */
        private function removeReadables(o:DisplayObject, dontRemoveTabChildrenHandler:Boolean):void
        {
            var i:int;
            if (o is DisplayObjectContainer)
            {
                for (i = 0; i < readableObjects.length; i++)
                {
                    if (isParent(DisplayObjectContainer(o), readableObjects[i]))
                    {
                        
                        readableObjects.splice(i, 1);
                        i = i - 1;  // because increment would skip one
                        
                        readableCandidates = [];
                        calculateCandidates = true;                 
                    }
                }
            }
        }
        
        /**
         *  @private
         *  Add or remove if tabbing properties change.
         */
        private function tabIndexChangeHandler(event:Event):void
        {
            calculateCandidates = true;
        }
    }
    
}
