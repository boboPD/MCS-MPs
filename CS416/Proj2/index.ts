type NavigationState = "next" | "previous";

function init(): void{
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
    const height = 300, width = 575, padding = 30;
    const xs = d3.scaleLinear().domain([1700, 2010]).range([0, width]);
    const ys = d3.scaleLinear().domain([6, 12]).range([height, 0]);

    const page1svg = d3.select("#page1");
    const line = d3.line().x(d => xs(d.Year)).y(d => ys(d.temperature));

    let temphighs: [number, number][] = data.map<[number, number]>(item => {
        return [xs(item.Year), ys(item.temperature + item.uncertainty)];
    });
    let templows: [number, number][] = data.map<[number, number]>(item => {
        return [xs(item.Year), ys(item.temperature - item.uncertainty)];
    });

    page1svg.append("g").attr("transform", `translate(${padding}, ${height + padding})`).call(d3.axisBottom(xs));
    page1svg.append("g").attr("transform", `translate(${padding}, ${padding})`).call(d3.axisLeft(ys));
    page1svg.append("g").append("path").attr("d", line(data)).attr("stroke", "red").attr("fill", "none");
    page1svg.append("g").append("path").attr("d", d3.line()(temphighs)).attr("stroke", "lightgray").attr("fill", "none");
    page1svg.append("g").append("path").attr("d", d3.line()(templows)).attr("stroke", "lightgray").attr("fill", "none");
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