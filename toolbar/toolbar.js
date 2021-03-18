(() => {

    let $ = function (selector) {
        return document.querySelector(selector);
    }

    let $$ = function (selector) {
        return document.querySelectorAll(selector);
    }

    HTMLElement.prototype.$ = function (selector) {
        return this.querySelector(selector);
    }

    HTMLElement.prototype.$$ = function (selector) {
        return this.querySelectorAll(selector);
    }

    function getAdjacentControl(toolbar, currentControl, backwards = false, edge = false) {
        let currentIndex, newIndex;
        const controls = toolbar.$$(".tpgi-toolbar-control");
        if (!controls) { return; }

        if (edge) {
            return controls[backwards ? 0 : controls.length - 1];
        }

        currentIndex = [...controls].indexOf(currentControl);
        newIndex = backwards ? currentIndex - 1 : currentIndex + 1;
        newIndex = newIndex >= controls.length ? 0 : (newIndex < 0 ? controls.length - 1 : newIndex);
        return controls[newIndex];
    }


    let toolbars = $$(".tpgi-toolbar");

    toolbars.forEach(toolbar => {
        toolbar.addEventListener("keydown", event => {
            if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) { return; }
            let newControl;
            switch (event.key) {
                case "ArrowRight":
                case "ArrowLeft":
                    newControl = getAdjacentControl(event.currentTarget , event.target, event.key === "ArrowLeft");
                    break;
                case "Home":
                case "End":
                    newControl = getAdjacentControl(event.currentTarget, event.target, event.key === "Home", true);
                    break;
            }
            console.log(event);
            if (newControl && newControl.focus) {
                newControl.focus();
            }
        });

        toolbar.addEventListener("focusin", event => {
            console.log(event);
        });
    });

})();