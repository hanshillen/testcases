package mx.controls
{
    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.ui.Mouse;
    
    import mx.core.IButton;
    import mx.core.IUITextField;
    import mx.core.UIComponent;
    import mx.core.mx_internal;
    import mx.managers.IFocusManagerComponent;
    
    use namespace mx_internal;
    [AccessibilityClass(implementation="mx.accessibility.MyLabelButtonAccImpl")]
    
    public class MyLabelButton extends Label implements IFocusManagerComponent
    {
        
        protected var accImplTarget:UIComponent;

        //--------------------------------------------------------------------------
        //
        //  Class mixins
        //
        //--------------------------------------------------------------------------
        
        /**
         *  @private
         *  Placeholder for mixin by LabelAccImpl.
         */
        mx_internal static var createAccessibilityImplementation:Function;
        
        public function MyLabelButton()
        {
            super();
            if (!accImplTarget)
            {
                accImplTarget = new UIComponent();
                addChild(DisplayObject(accImplTarget));
            }
            addEventListener(KeyboardEvent.KEY_UP, handleKeyUp);
        }
        
        
        //Also allow the Enter and Space key to be used to trigger click events
        private function handleKeyUp(event:KeyboardEvent):void
        {
            if (event.keyCode == 13 || event.keyCode == 32)
            {
                var mouseEvent:MouseEvent = new MouseEvent(MouseEvent.CLICK, event.bubbles, event.bubbles, 0,0,
                    null, event.ctrlKey, event.altKey);
                dispatchEvent(mouseEvent);
            }
                
        }

        //--------------------------------------------------------------------------
        //
        //  Overridden methods: UIComponent
        //
        //--------------------------------------------------------------------------
        
        
        /**
         *  @private
         */
        override protected function initializeAccessibility():void
        {
            if (MyLabelButton.createAccessibilityImplementation != null)
                MyLabelButton.createAccessibilityImplementation(this);
        }
        
        override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
        {
            super.updateDisplayList(unscaledWidth, unscaledHeight);
            updateAccImplTarget(unscaledWidth, unscaledHeight);
        }
        
        private function updateAccImplTarget(width:int, height:int):void
        {
            var g:Graphics = accImplTarget.graphics;
            g.clear();
            g.lineStyle(0, 0x000000, 0);
            g.drawRect(0, 0, width, height);
        }
        
        mx_internal function getAccImplTarget():UIComponent
        {
            return accImplTarget;    
        }
    }
}