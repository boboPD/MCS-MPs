"use strict";
var complete_data;
function init() {
    sessionStorage.setItem("currentPage", "1");
    var p1 = fetchChart1Data().then(function (data) { return buildChart1(data); });
    var p2 = fetchChart2Data().then(function (data) { return buildChart2(data); });
    var p3 = fetchChart3Data().then(function (data) { return complete_data = data; });
    Promise.all([p1, p2, p3]).then(function () {
        document.getElementById("loadingPage").hidden = true;
        document.getElementById("mainPage").hidden = false;
        d3.select("#page1div").classed("hiddenPage", false).classed("currentPage", true);
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
    if (currentPage == 3) {
        d3.select("#page3").selectAll("svg").html("");
    }
    var nextPage = moveDirection == 'next' ? currentPage + 1 : currentPage - 1;
    d3.select("#page" + currentPage + "div").classed("hiddenPage", true).classed("currentPage", false);
    d3.select("#page" + nextPage + "div").classed("hiddenPage", false).classed("currentPage", true);
    sessionStorage.setItem("currentPage", nextPage.toString());
    document.getElementById("previousBtn").disabled = !isButtonReq("previous");
    document.getElementById("nextBtn").disabled = !isButtonReq("next");
}
function buildChart1(data) {
    var height = 500, width = 1000, padding = 20;
    var xs = d3.scaleLinear().domain([1740, 2020]).range([0, width - 2 * padding]);
    var ys = d3.scaleLinear().domain([4, 12]).range([height - 2 * padding, 0]);
    var page1svg = d3.select("#page1").attr("viewBox", "0 0 " + width + " " + height);
    var line = d3.line().x(function (d) { return xs(d.Year); }).y(function (d) { return ys(d.temperature); });
    var temphighs = data.map(function (item) {
        return [xs(item.Year), ys(item.temperature + item.uncertainty)];
    });
    var templows = data.map(function (item) {
        return [xs(item.Year), ys(item.temperature - item.uncertainty)];
    });
    page1svg.append("g").attr("transform", "translate(" + padding + ", " + (height - padding) + ")").call(d3.axisBottom(xs).ticks(28));
    page1svg.append("g").attr("transform", "translate(" + padding + ", " + padding + ")").call(d3.axisLeft(ys));
    var linegrp = page1svg.append("g").attr("transform", "translate(" + padding + ", " + padding + ")");
    linegrp.append("g").append("path").attr("d", line(data)).attr("stroke", "blue").attr("fill", "none");
    linegrp.append("g").append("path").attr("d", d3.line()(temphighs)).attr("stroke", "lightgray").attr("fill", "none");
    linegrp.append("g").append("path").attr("d", d3.line()(templows)).attr("stroke", "lightgray").attr("fill", "none");
    var eventData = {
        1880: ["Industrial revolution", 8.047],
        1887: ["Production of gasoline powered automobiles", 7.933],
        1908: ["Mass production of automobiles", 8.202],
        1939: ["Invention of the jet engine", 8.673],
        1970: ["Start of the PC age", 8.656]
    };
    linegrp.append("g").selectAll("circle").data(Object.keys(eventData)).enter().append("circle")
        .attr("cx", function (d) { return xs(parseInt(d)); })
        .attr("cy", function (d) { return ys(eventData[parseInt(d)][1]); })
        .attr("fill", "red")
        .attr("r", 3);
    var annoGrp = page1svg.append("g").attr("transform", "translate(" + padding + ", " + padding + ")");
    annoGrp.append("g").selectAll("line").data(Object.keys(eventData)).enter().append("line")
        .attr("x1", function (d) { return xs(parseInt(d)); })
        .attr("x2", function (d) { return xs(parseInt(d)); })
        .attr("y1", function (d) { return ys(eventData[parseInt(d)][1]); })
        .attr("y2", function (d, i) {
        var factor = i % 2 == 1 ? 1 : -1;
        var y = ys(eventData[parseInt(d)][1]) + 75 * factor;
        return i != 2 ? y : y - 50;
    })
        .attr("stroke", "black");
    annoGrp.append("g").selectAll("text").data(Object.keys(eventData)).enter().append("text")
        .attr("x", function (d) { return xs(parseInt(d) - 15); })
        .attr("y", function (d, i) {
        var factor = i % 2 == 1 ? 1 : -1;
        var y = ys(eventData[parseInt(d)][1]) + 85 * factor;
        return i != 2 ? y : y - 50;
    })
        .html(function (d) { return eventData[parseInt(d)][0]; })
        .classed("small", true);
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
function fetchChart2Data() {
    var res = {};
    return d3.csv("https://raw.githubusercontent.com/boboPD/MCS-MPs/master/CS416/Proj2/data/warming.csv").then(function (data) {
        var _a;
        for (var _i = 0, data_2 = data; _i < data_2.length; _i++) {
            var item = data_2[_i];
            if (item["Country"] && item["Warming"] && item["Error"]) {
                res[item["Country"]] = {
                    Warming: parseFloat(item["Warming"]),
                    Error: parseFloat(item["Error"]),
                    Region: (_a = item["Region"]) !== null && _a !== void 0 ? _a : ""
                };
            }
        }
        return res;
    });
}
function fetchChart3Data() {
    var res = {};
    return d3.csv("https://raw.githubusercontent.com/boboPD/MCS-MPs/master/CS416/Proj2/data/data.csv").then(function (data) {
        var _a, _b, _c, _d;
        for (var _i = 0, data_3 = data; _i < data_3.length; _i++) {
            var item = data_3[_i];
            if (item["Country"]) {
                if (!(item["Country"] in res)) {
                    res[item["Country"]] = [];
                }
                res[item["Country"]].push({
                    Month: (_a = item["Month"]) !== null && _a !== void 0 ? _a : "Unknown",
                    Year: parseInt((_b = item["Year"]) !== null && _b !== void 0 ? _b : "-1"),
                    Temperature: parseFloat((_c = item["Temperature"]) !== null && _c !== void 0 ? _c : "999"),
                    StationName: (_d = item["StationName"]) !== null && _d !== void 0 ? _d : "Unknown"
                });
            }
        }
        return res;
    });
}
function buildChart2(data) {
    return d3.json("https://raw.githubusercontent.com/holtzy/D3-graph-gallery/master/DATA/world.geojson").then(function (topo) {
        var proj = d3.geoEquirectangular().scale(60).translate([200, 100]);
        var path = d3.geoPath(proj);
        var colorScale = d3.scaleLinear()
            .domain([0, 4])
            .range(["blue", "red"]);
        var tooltip = d3.select("body")
            .append("div")
            .classed("tooltip", true);
        var page2svg = d3.select("#page2").attr("viewBox", "0 0 400 300");
        var legend = page2svg.append("g").attr("id", "legend2").attr("transform", "translate(180, 0)");
        legend.append("text").text("0°C").attr("x", 0).attr("y", 4).classed("temp-legend", true);
        legend.selectAll("rect").data(d3.range(0, 4, 0.05)).enter()
            .append("rect").attr("fill", function (d) { return colorScale(d); }).attr("width", 0.5).attr("height", 5)
            .attr("x", function (d, i) { return 7 + i * 0.5; });
        legend.append("text").text("4°C").attr("x", 47).attr("y", 4).classed("temp-legend", true);
        page2svg.append("g").selectAll("path").data(topo.features).join("path")
            .attr("d", path).attr("fill", function (d) {
            if (data[d.properties.name])
                return colorScale(data[d.properties.name].Warming);
            else
                return "darkgrey";
        }).on("click", function (mouseEventDetails, data) {
            var countryName = data.properties.name;
            if (countryName in complete_data) {
                buildChart3(countryName);
                updatePage("next");
            }
            else {
                alert("Sorry could not find detailed temperature data for this country");
            }
        }).on("mouseenter", function (mouseEventDetails, clickData) {
            mouseEventDetails.path[0].style.opacity = "50%";
            tooltip.html("Country: " + clickData.properties.name + " <br /> Warming: " + data[clickData.properties.name].Warming);
            tooltip.style("visibility", "visible");
        }).on("mousemove", function (mouseEventDetails, data) {
            tooltip.style("top", (mouseEventDetails.pageY - 35) + "px").style("left", (mouseEventDetails.pageX + 10) + "px");
        }).on("mouseleave", function (mouseEventDetails, data) {
            mouseEventDetails.path[0].style.opacity = "100%";
            tooltip.style("visibility", "hidden");
            tooltip.html("");
        });
    });
}
function buildChart3(country) {
    d3.select("#page3").selectAll("svg").data(["yearlyChart", "monthlyChart"]).enter().append("svg").attr("id", function (d) { return d; }).attr("width", "100%").attr("height", "500px");
    var countrySpecificData = complete_data[country];
    var yearlyData = getAvgTempByYear(countrySpecificData);
    var minTemp = Math.min.apply(Math, yearlyData.map(function (obj) { return obj.AvgTemp; }));
    var maxTemp = Math.max.apply(Math, yearlyData.map(function (obj) { return obj.AvgTemp; }));
    var minYear = Math.min.apply(Math, yearlyData.map(function (obj) { return obj.Year; }));
    var maxYear = Math.max.apply(Math, yearlyData.map(function (obj) { return obj.Year; }));
    var height = 500, width = 1000, padding = 70;
    var xsChart1 = d3.scaleLinear().domain([minYear, maxYear]).range([0, width - 2 * padding]);
    var ysChart1 = d3.scaleLinear().domain([minTemp, maxTemp]).range([height - 2 * padding, 0]);
    var firstsvg = d3.select("#yearlyChart").attr("viewbox", "0 0 " + width + " " + height);
    firstsvg.append("g").attr("transform", "translate(" + padding + ", " + (height - padding) + ")").call(d3.axisBottom(xsChart1).ticks(10));
    firstsvg.append("text").attr("y", height - padding / 2).attr("x", width / 2).text("Year");
    firstsvg.append("g").attr("transform", "translate(" + padding + ", " + padding + ")").call(d3.axisLeft(ysChart1).ticks(10));
    firstsvg.append("text").attr("y", 20).attr("x", (height + padding) / -2).text("Temperature").attr("transform", "rotate(-90)");
    var line = d3.line().x(function (d) { return xsChart1(d.Year); }).y(function (d) { return ysChart1(d.AvgTemp); });
    firstsvg.append("g").attr("transform", "translate(" + padding + ", " + padding + ")").append("path").attr("d", line(yearlyData)).attr("stroke", "blue").attr("fill", "none");
    var months = ["Jan", "Feb", "March", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    var colours = ["red", "blue", "green", "purple", "black", "grey", "darkgreen", "magenta", "brown", "slateblue", "grey1", "orange"];
    var monthDataAvgOverCities = {};
    var legendWidth = 50;
    var overallMinTemp = 1000;
    var overallMaxTemp = -1000;
    var minYearc2 = Math.min.apply(Math, yearlyData.map(function (obj) { return obj.Year; }));
    var maxYearc2 = Math.max.apply(Math, yearlyData.map(function (obj) { return obj.Year; }));
    var _loop_1 = function (item) {
        var monthData = countrySpecificData.filter(function (obj) { return obj.Month == item; });
        monthDataAvgOverCities[item] = getAvgTempByYear(monthData);
        var monthlyMinTemp = Math.min.apply(Math, monthDataAvgOverCities[item].map(function (obj) { return obj.AvgTemp; }));
        var monthlyMaxTemp = Math.max.apply(Math, monthDataAvgOverCities[item].map(function (obj) { return obj.AvgTemp; }));
        overallMinTemp = overallMinTemp > monthlyMinTemp ? monthlyMinTemp : overallMinTemp;
        overallMaxTemp = overallMaxTemp < monthlyMaxTemp ? monthlyMaxTemp : overallMaxTemp;
    };
    for (var _i = 0, months_1 = months; _i < months_1.length; _i++) {
        var item = months_1[_i];
        _loop_1(item);
    }
    var xsChart2 = d3.scaleLinear().domain([minYearc2, maxYearc2]).range([0, width - (2 * padding + legendWidth)]);
    var ysChart2 = d3.scaleLinear().domain([overallMinTemp, overallMaxTemp]).range([height - 2 * padding, 0]);
    var secondsvg = d3.select("#monthlyChart").attr("viewbox", "0 0 " + width + " " + height);
    secondsvg.append("g").attr("transform", "translate(" + padding + ", " + (height - padding) + ")").call(d3.axisBottom(xsChart2).ticks(10));
    secondsvg.append("text").attr("y", height - padding / 2).attr("x", width / 2).text("Year");
    secondsvg.append("g").attr("transform", "translate(" + padding + ", " + padding + ")").call(d3.axisLeft(ysChart2).ticks(10));
    secondsvg.append("text").attr("y", 20).attr("x", (height + padding) / -2).text("Temperature").attr("transform", "rotate(-90)");
    var legend = secondsvg.append("g").attr("transform", "translate(" + (width - (padding + legendWidth) + 20) + ", " + (height / 2 - padding) + ")").classed("legend", true);
    var legendItems = legend.selectAll("g").data(d3.range(12)).enter().append("g");
    legendItems.append("rect").attr("width", 12).attr("height", 12).attr("fill", function (d) { return colours[d]; }).attr("y", function (d) { return 20 * d; });
    legendItems.append("text").attr("x", 17).attr("y", function (d) { return 20 * d + 12; }).text(function (d) { return months[d]; });
    var monthline = d3.line().x(function (d) { return xsChart2(d.Year); }).y(function (d) { return ysChart2(d.AvgTemp); });
    for (var i = 0; i < 12; i++) {
        secondsvg.append("g").attr("transform", "translate(" + padding + ", " + padding + ")").append("path").attr("d", monthline(monthDataAvgOverCities[months[i]])).attr("stroke", colours[i]).attr("fill", "none");
    }
}
function getAvgTempByYear(data) {
    var temp = data.reduce(function (result, currentObj) {
        if (currentObj["Year"] in result) {
            result[currentObj["Year"]].Temp += currentObj.Temperature;
            result[currentObj["Year"]].Count++;
        }
        else {
            result[currentObj["Year"]] = {
                Temp: currentObj.Temperature,
                Count: 1
            };
        }
        return result;
    }, {});
    var finalResult = [];
    for (var year in temp) {
        finalResult.push({
            AvgTemp: temp[year].Temp / temp[year].Count,
            Year: parseInt(year)
        });
    }
    return finalResult;
}
//# sourceMappingURL=index.js.map