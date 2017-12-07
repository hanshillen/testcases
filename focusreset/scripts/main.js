$(function () {
    $(".nextBtn,.prevBtn").click(function (e) {
        e.preventDefault();
        //Figure out which page to show and what the prev and next pages are
        var $pages = $(".page");
        var $link = $(this);
        var targetId = $link.attr("href").replace("#", "");
        var $currentPage = $("#" + targetId);
        var currentIndex = $pages.index($currentPage);
        var nextIndex = currentIndex + 1,
            prevIndex = currentIndex - 1;
        if (!$currentPage.length || currentIndex === -1) {
            return;
        }
        var $nextPage = $pages.eq(nextIndex);
        var $prevPage = currentIndex > 0 ? $pages.eq(prevIndex) : $();

        // Swap pages
        $(".activePage").removeClass("activePage");
        $currentPage.addClass("activePage");

        // briefly make heading focusable and move focus to it 
        var $heading = $currentPage.find("h2:eq(0)").attr("tabindex", "-1");
        $heading.focus().removeAttr("tabindex");

        // Update paging controls
        if (!$prevPage.length) {
            $(".prevBtn").parent().addClass("invisible");
        } else {
            $(".prevBtn").attr("href", "#" + $prevPage.attr("id")).attr("aria-label", "page " + (prevIndex + 1))
                .parent().removeClass("invisible");
        }
        if (!$nextPage.length) {
            $(".nextBtn").parent().addClass("invisible");
        } else {
            $(".nextBtn").attr("href", "#" + $nextPage.attr("id")).attr("aria-label", "page " + (nextIndex + 1))
                .parent().removeClass("invisible");
        }
    });
});
