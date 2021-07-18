
function draw() {
    d3.select("body").select("svg").append("circle").attr("cx", 150).attr("cy", 150).attr("r", 20);
}
function init() {
    sessionStorage.setItem("currentPage", "1");
}
function getCurrentPage() {
    var _a;
    return parseInt((_a = sessionStorage.getItem("currentPage")) !== null && _a !== void 0 ? _a : "1");
}
function isButtonReq(moveDirection) {
    var currentPage = getCurrentPage();
    return !((currentPage == 1 && moveDirection == "previous") || (currentPage == 3 && moveDirection == "next"));
}
function updatePage(moveDirection) {
    var currentPage = getCurrentPage();
    var nextPage = moveDirection == 'next' ? currentPage + 1 : currentPage - 1;
    d3.select("#page" + currentPage).classed("hiddenPage", true).classed("currentPage", false);
    d3.select("#page" + nextPage).classed("currentPage", true);
    sessionStorage.setItem("currentPage", nextPage.toString());
    document.getElementById("previousBtn").disabled = !isButtonReq("previous");
    document.getElementById("nextBtn").disabled = !isButtonReq("next");
}
//# sourceMappingURL=index.js.map