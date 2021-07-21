type NavigationState = "next" | "previous";

function init(): void {
    sessionStorage.setItem("currentPage", "1");
    const p1 = fetchChart1Data().then(data => buildChart1(data));
    Promise.all([p1]).then(() => {
        document.getElementById("loadingPage")!.hidden = true;
        document.getElementById("mainPage")!.hidden = false;
        d3.select("#page1").classed("hiddenPage", false).classed("currentPage", true);
    });
}

function getCurrentPage(): number {
    return parseInt(sessionStorage.getItem("currentPage") ?? "1")
}

function isButtonReq(moveDirection: NavigationState): boolean {
    const currentPage: number = getCurrentPage();
    return !((currentPage == 1 && moveDirection == "previous") || (currentPage == 3 && moveDirection == "next"))
}

function updatePage(moveDirection: NavigationState): void{
    const currentPage: number = getCurrentPage();
    const nextPage = moveDirection == 'next' ? currentPage + 1 : currentPage - 1;
    
    d3.select(`#page${currentPage}`).classed("hiddenPage", true).classed("currentPage", false);
    d3.select(`#page${nextPage}`).classed("hiddenPage", false).classed("currentPage", true);

    sessionStorage.setItem("currentPage", nextPage.toString());

    (<HTMLButtonElement>document.getElementById("previousBtn")).disabled = !isButtonReq("previous");
    (<HTMLButtonElement>document.getElementById("nextBtn")).disabled = !isButtonReq("next");
}

function buildChart1(data: Chart1DataModel[]) {
    const height = 300, width = 800, padding = 30;
    const xs = d3.scaleLinear().domain([1740, 2020]).range([0, width]);
    const ys = d3.scaleLinear().domain([4, 12]).range([height, 0]);

    const page1svg = d3.select("#page1");
    const line = d3.line().x(d => xs(d.Year)).y(d => ys(d.temperature));

    let temphighs: [number, number][] = data.map<[number, number]>(item => {
        return [xs(item.Year), ys(item.temperature + item.uncertainty)];
    });
    let templows: [number, number][] = data.map<[number, number]>(item => {
        return [xs(item.Year), ys(item.temperature - item.uncertainty)];
    });

    page1svg.append("g").attr("transform", `translate(${padding}, ${height + padding})`).call(d3.axisBottom(xs).ticks(28));
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

interface Chart1DataModel {
    Year: number;
    temperature: number;
    uncertainty: number;
}