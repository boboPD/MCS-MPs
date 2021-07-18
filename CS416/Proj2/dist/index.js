"use strict";
function init() {
    sessionStorage.setItem("currentPage", "1");
    var p1 = fetchChart1Data().then(function (data) { return buildChart1(data); });
    Promise.all([p1]).then(function () {
        document.getElementById("loadingPage").hidden = true;
        document.getElementById("mainPage").hidden = false;
        d3.select("#page1").classed("hiddenPage", false).classed("currentPage", true);
    });
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
    d3.select("#page" + nextPage).classed("hiddenPage", false).classed("currentPage", true);
    sessionStorage.setItem("currentPage", nextPage.toString());
    document.getElementById("previousBtn").disabled = !isButtonReq("previous");
    document.getElementById("nextBtn").disabled = !isButtonReq("next");
}
function buildChart1(data) {
    var height = 300, width = 575, padding = 30;
    var xs = d3.scaleLinear().domain([1700, 2010]).range([0, width]);
    var ys = d3.scaleLinear().domain([6, 12]).range([height, 0]);
    var page1svg = d3.select("#page1");
    var line = d3.line().x(function (d) { return xs(d.Year); }).y(function (d) { return ys(d.temperature); });
    var temphighs = data.map(function (item) {
        return [xs(item.Year), ys(item.temperature + item.uncertainty)];
    });
    var templows = data.map(function (item) {
        return [xs(item.Year), ys(item.temperature - item.uncertainty)];
    });
    page1svg.append("g").attr("transform", "translate(" + padding + ", " + (height + padding) + ")").call(d3.axisBottom(xs));
    page1svg.append("g").attr("transform", "translate(" + padding + ", " + padding + ")").call(d3.axisLeft(ys));
    page1svg.append("g").append("path").attr("d", line(data)).attr("stroke", "red").attr("fill", "none");
    page1svg.append("g").append("path").attr("d", d3.line()(temphighs)).attr("stroke", "lightgray").attr("fill", "none");
    page1svg.append("g").append("path").attr("d", d3.line()(templows)).attr("stroke", "lightgray").attr("fill", "none");
}
function fetchChart1Data() {
    var res = [];
    return d3.csv("https://raw.githubusercontent.com/boboPD/MCS-MPs/master/CS416/Proj2/data/global_avg.csv").then(function (data) {
        for (var _i = 0, data_1 = data; _i < data_1.length; _i++) {
            var item = data_1[_i];
            if (item["Year"] && item["temperature"] && item["uncertainty"]) {
                res.push({
                    Year: parseInt(item["Year"]),
                    temperature: parseFloat(item["temperature"]),
                    uncertainty: parseFloat(item["uncertainty"])
                });
            }
        }
        return res;
    });
}
//# sourceMappingURL=index.js.map