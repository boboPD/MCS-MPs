type NavigationState = "next" | "previous";

let complete_data:{ [country: string]: CountryDetailData[] };

function init(): void {
    sessionStorage.setItem("currentPage", "1");
    const p1 = fetchChart1Data().then(data => buildChart1(data));
    const p2 = fetchChart2Data().then(data => {return buildChart2(data)});
    const p3 = fetchChart3Data().then(data => complete_data = data);
    Promise.all([p1, p2, p3]).then(() => {
        document.getElementById("loadingPage")!.hidden = true;
        document.getElementById("mainPage")!.hidden = false;
        d3.select("#page1div").classed("hiddenPage", false).classed("currentPage", true);
    });
}

function getCurrentPage(): number {
    return parseInt(sessionStorage.getItem("currentPage") ?? "1")
}

function isButtonReq(moveDirection: NavigationState): boolean {
    const currentPage: number = getCurrentPage();
    return !((currentPage == 1 && moveDirection == "previous") || (currentPage == 3 && moveDirection == "next"));
}

function updatePage(moveDirection: NavigationState): void{
    const currentPage: number = getCurrentPage();

    if (currentPage == 3) {
        d3.select("#page3").selectAll("svg").html("");
    }

    const nextPage = moveDirection == 'next' ? currentPage + 1 : currentPage - 1;
    
    d3.select(`#page${currentPage}div`).classed("hiddenPage", true).classed("currentPage", false);
    d3.select(`#page${nextPage}div`).classed("hiddenPage", false).classed("currentPage", true);

    sessionStorage.setItem("currentPage", nextPage.toString());

    (<HTMLButtonElement>document.getElementById("previousBtn")).disabled = !isButtonReq("previous");
    (<HTMLButtonElement>document.getElementById("nextBtn")).disabled = !isButtonReq("next");
}

function buildChart1(data: Chart1DataModel[]) {
    const height = 500, width = 1000, padding = 20;
    const xs = d3.scaleLinear().domain([1740, 2020]).range([0, width - 2 * padding]);
    const ys = d3.scaleLinear().domain([4, 12]).range([height - 2 * padding, 0]);

    const page1svg = d3.select("#page1").attr("viewBox", `0 0 ${width} ${height}`);
    const line = d3.line().x(d => xs(d.Year)).y(d => ys(d.temperature));

    let temphighs: [number, number][] = data.map<[number, number]>(item => {
        return [xs(item.Year), ys(item.temperature + item.uncertainty)];
    });
    let templows: [number, number][] = data.map<[number, number]>(item => {
        return [xs(item.Year), ys(item.temperature - item.uncertainty)];
    });

    page1svg.append("g").attr("transform", `translate(${padding}, ${height - padding})`).call(d3.axisBottom(xs).ticks(28));
    page1svg.append("g").attr("transform", `translate(${padding}, ${padding})`).call(d3.axisLeft(ys));

    const linegrp = page1svg.append("g").attr("transform", `translate(${padding}, ${padding})`);
    linegrp.append("g").append("path").attr("d", line(data)).attr("stroke", "blue").attr("fill", "none");
    linegrp.append("g").append("path").attr("d", d3.line()(temphighs)).attr("stroke", "lightgray").attr("fill", "none");
    linegrp.append("g").append("path").attr("d", d3.line()(templows)).attr("stroke", "lightgray").attr("fill", "none");

    // Adding important events data
    const eventData: {[year: number]: [string, number]} = {
        1880: ["Industrial revolution", 8.047],
        1887: ["Production of gasoline powered automobiles", 7.933],
        1908: ["Mass production of automobiles", 8.202],
        1939: ["Invention of the jet engine", 8.673],
        1970: ["Start of the PC age", 8.656]
    };

    linegrp.append("g").selectAll("circle").data(Object.keys(eventData)).enter().append("circle")
            .attr("cx", (d) => xs(parseInt(d)))
            .attr("cy", (d) => ys(eventData[parseInt(d)][1]))
            .attr("fill", "red")
            .attr("r", 3);
    
    // Adding annotations
    const annoGrp = page1svg.append("g").attr("transform", `translate(${padding}, ${padding})`);
    annoGrp.append("g").selectAll("line").data(Object.keys(eventData)).enter().append("line")
           .attr("x1", (d) => xs(parseInt(d)))
           .attr("x2", (d) => xs(parseInt(d)))
           .attr("y1", (d) => ys(eventData[parseInt(d)][1]))
           .attr("y2", (d, i) => {
               const factor = i%2 == 1 ? 1 : -1;
               const y = ys(eventData[parseInt(d)][1]) + 75 * factor
               return i != 2 ? y : y - 50;
            })
           .attr("stroke", "black");
    annoGrp.append("g").selectAll("text").data(Object.keys(eventData)).enter().append("text")
           .attr("x", (d) => xs(parseInt(d) - 15))
           .attr("y", (d, i) => {
                const factor = i%2 == 1 ? 1 : -1;
                const y = ys(eventData[parseInt(d)][1]) + 85 * factor
                return i != 2 ? y : y - 50;
           })
           .html((d) => eventData[parseInt(d)][0])
           .classed("small", true);

}

function fetchChart1Data(): Promise<Chart1DataModel[]> {
    let res: Chart1DataModel[] = [];

    return d3.csv("https://raw.githubusercontent.com/boboPD/MCS-MPs/master/CS416/Proj2/data/global_avg.csv").then(
        data => {
            for (const item of data) {
                if (item["Year"] && item["temperature"] && item["uncertainty"]) {
                    res.push({
                        Year: parseInt(item["Year"]),
                        temperature: parseFloat(item["temperature"]),
                        uncertainty: parseFloat(item["uncertainty"])
                    });
                }
            }

            return res;
        }
    );
}

function fetchChart2Data(): Promise<{ [country: string]: CountryData}> {
    let res: { [country: string]: CountryData} = {};

    return d3.csv("https://raw.githubusercontent.com/boboPD/MCS-MPs/master/CS416/Proj2/data/warming.csv").then(
        data => {
            for (const item of data) {
                if (item["Country"] && item["Warming"] && item["Error"]) {
                    res[item["Country"]] = {
                        Warming: parseFloat(item["Warming"]),
                        Error: parseFloat(item["Error"]),
                        Region: item["Region"] ?? ""
                    };
                }
            }

            return res;
        }
    );
}

function fetchChart3Data(): Promise<{ [country: string]: CountryDetailData[]}> {
    let res: { [country: string]: CountryDetailData[]} = {};

    return d3.csv("https://raw.githubusercontent.com/boboPD/MCS-MPs/master/CS416/Proj2/data/data.csv").then(
        data => {
            for (const item of data) {
                if (item["Country"]) {
                    if (!(item["Country"] in res)) {
                        res[item["Country"]] = [];
                    }
                    res[item["Country"]].push({
                        Month: item["Month"] ?? "Unknown",
                        Year: parseInt(item["Year"] ?? "-1"),
                        Temperature: parseFloat(item["Temperature"] ?? "999"),
                        StationName: item["StationName"] ?? "Unknown"
                    });
                }
            }

            return res;
        }
    );
}

function buildChart2(data: { [country: string]: CountryData}): Promise<any> {
    return d3.json("https://raw.githubusercontent.com/holtzy/D3-graph-gallery/master/DATA/world.geojson").then(
        (topo: any) => {
            const proj = d3.geoEquirectangular().scale(60).translate([200,100]);
            const path = d3.geoPath(proj);
            const colorScale = d3.scaleLinear()
                                 .domain([0, 4])
                                 .range(["blue", "red"]);

            var tooltip = d3.select("body")
                            .append("div")
                            .classed("tooltip", true);
    
            const page2svg = d3.select("#page2").attr("viewBox", `0 0 400 300`);
            const legend = page2svg.append("g").attr("id", "legend2").attr("transform", "translate(180, 0)");
            legend.append("text").text("0°C").attr("x", 0).attr("y", 4).classed("temp-legend", true);
            legend.selectAll("rect").data(d3.range(0, 4, 0.05)).enter()
                                .append("rect").attr("fill", (d) => colorScale(d)).attr("width", 0.5).attr("height", 5)
                                .attr("x", (d, i) => 7 + i * 0.5);
            legend.append("text").text("4°C").attr("x", 47).attr("y", 4).classed("temp-legend", true);
            page2svg.append("g").selectAll("path").data(topo.features).join("path")
                    .attr("d", path).attr("fill", (d: any) => {
                        if(data[d.properties.name])
                            return colorScale(data[d.properties.name].Warming);
                        else
                            return "darkgrey";
                    }).on("click", (mouseEventDetails: any, data: any) => {
                        const countryName: string = data.properties.name;
                        if (countryName in complete_data) {
                            buildChart3(countryName);
                            updatePage("next");
                        } else {
                            alert("Sorry could not find detailed temperature data for this country");
                        }
                        
                    }).on("mouseenter", (mouseEventDetails: any, data: any) => {
                        mouseEventDetails.path[0].style.opacity = "50%";
                        tooltip.html(data.properties.name);
                        tooltip.style("visibility", "visible");
                    }).on("mousemove", (mouseEventDetails: any, data: any) => {
                        tooltip.style("top", (mouseEventDetails.pageY-20)+"px").style("left",(mouseEventDetails.pageX+10)+"px");
                    }).on("mouseleave", (mouseEventDetails: any, data: any) => {
                        mouseEventDetails.path[0].style.opacity = "100%";
                        tooltip.style("visibility", "hidden");
                        tooltip.html("");
                    });
        }
    );
}

function buildChart3(country: string) {
    d3.select("#page3").selectAll("svg").data(["yearlyChart", "monthlyChart"]).enter().append("svg").attr("id", (d) => d).attr("width", "100%").attr("height", "500px");

    const countrySpecificData: CountryDetailData[] = complete_data[country];

    // Build the first chart
    const yearlyData: Chart3Model[] = getAvgTempByYear(countrySpecificData);
    const minTemp: number = Math.min(...yearlyData.map(obj => obj.AvgTemp));
    const maxTemp: number = Math.max(...yearlyData.map(obj => obj.AvgTemp));
    const minYear: number = Math.min(...yearlyData.map(obj => obj.Year));
    const maxYear: number = Math.max(...yearlyData.map(obj => obj.Year));

    const height = 500, width = 1000, padding = 70;
    const xsChart1 = d3.scaleLinear().domain([minYear, maxYear]).range([0, width - 2*padding]);
    const ysChart1 = d3.scaleLinear().domain([minTemp, maxTemp]).range([height - 2*padding, 0]);

    const firstsvg = d3.select("#yearlyChart").attr("viewbox", `0 0 ${width} ${height}`);

    firstsvg.append("g").attr("transform", `translate(${padding}, ${height - padding})`).call(d3.axisBottom(xsChart1).ticks(10));
    firstsvg.append("text").attr("y", height - padding/2).attr("x", width/2).text("Year");

    firstsvg.append("g").attr("transform", `translate(${padding}, ${padding})`).call(d3.axisLeft(ysChart1).ticks(10));
    firstsvg.append("text").attr("y", 20).attr("x", (height+padding)/-2).text("Temperature").attr("transform", "rotate(-90)");

    const line = d3.line().x(d => xsChart1(d.Year)).y(d => ysChart1(d.AvgTemp));

    firstsvg.append("g").attr("transform", `translate(${padding}, ${padding})`).append("path").attr("d", line(yearlyData)).attr("stroke", "blue").attr("fill", "none");

    // Build second chart
    const months = ["Jan", "Feb", "March", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    const colours = ["red", "blue", "green", "purple", "black", "grey", "darkgreen", "magenta", "brown", "slateblue", "grey1", "orange"];
    const monthDataAvgOverCities: {[month: string]: Chart3Model[]} = {};

    let overallMinTemp: number = 1000;
    let overallMaxTemp: number = -1000;
    const minYearc2: number = Math.min(...yearlyData.map(obj => obj.Year));
    const maxYearc2: number = Math.max(...yearlyData.map(obj => obj.Year));

    for (let item of months) {
        const monthData = countrySpecificData.filter((obj) => obj.Month == item);
        monthDataAvgOverCities[item] = getAvgTempByYear(monthData);

        const monthlyMinTemp = Math.min(...monthDataAvgOverCities[item].map(obj => obj.AvgTemp));
        const monthlyMaxTemp = Math.max(...monthDataAvgOverCities[item].map(obj => obj.AvgTemp));

        overallMinTemp = overallMinTemp > monthlyMinTemp ? monthlyMinTemp : overallMinTemp;
        overallMaxTemp = overallMaxTemp < monthlyMaxTemp ? monthlyMaxTemp : overallMaxTemp;
    }

    const xsChart2 = d3.scaleLinear().domain([minYearc2, maxYearc2]).range([0, width - 2*padding]);
    const ysChart2 = d3.scaleLinear().domain([overallMinTemp, overallMaxTemp]).range([height - 2*padding, 0]);
    const secondsvg = d3.select("#monthlyChart").attr("viewbox", `0 0 ${width} ${height}`);

    secondsvg.append("g").attr("transform", `translate(${padding}, ${height - padding})`).call(d3.axisBottom(xsChart2).ticks(10));
    secondsvg.append("text").attr("y", height - padding/2).attr("x", width/2).text("Year");

    secondsvg.append("g").attr("transform", `translate(${padding}, ${padding})`) .call(d3.axisLeft(ysChart2).ticks(10));
    secondsvg.append("text").attr("y", 20).attr("x", (height+padding)/-2).text("Temperature").attr("transform", "rotate(-90)");

    const monthline = d3.line().x(d => xsChart2(d.Year)).y(d => ysChart2(d.AvgTemp));

    for (let i=0;i<12;i++) {
        secondsvg.append("g").attr("transform", `translate(${padding}, ${padding})`).append("path").attr("d", monthline(monthDataAvgOverCities[months[i]])).attr("stroke", colours[i]).attr("fill", "none");
    }
}

function getAvgTempByYear(data: CountryDetailData[]): Chart3Model[] {
    const temp: {[Year: number]: any} = data.reduce((result: any, currentObj) => {
        if (currentObj["Year"] in result) {
            result[currentObj["Year"]].Temp += currentObj.Temperature;
            result[currentObj["Year"]].Count++;
        } else {
            result[currentObj["Year"]] = {
                Temp: currentObj.Temperature,
                Count: 1
            }
        }
        return result;
    }, {});

    let finalResult: Chart3Model[] = [];
    for(let year in temp){
        finalResult.push({
            AvgTemp: temp[year].Temp/temp[year].Count,
            Year: parseInt(year)
        });
    }

    return finalResult;
}

interface Chart1DataModel {
    Year: number;
    temperature: number;
    uncertainty: number;
}

interface CountryData {
    Warming: number;
    Error: number;
    Region: string;
}

interface CountryDetailData {
    Temperature: number;
    Year: number;
    Month: string;
    StationName: string;
}

interface Chart3Model {
    AvgTemp: number;
    Year: number;
}