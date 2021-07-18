import * as d3 from 'd3';

type NavigationState = "next" | "previous";

function draw(){
    d3.select("body").select("svg").append("circle").attr("cx", 150).attr("cy", 150).attr("r", 20);
}

function init(): void{
    sessionStorage.setItem("currentPage", "1");
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
    d3.select(`#page${nextPage}`).classed("currentPage", true);

    sessionStorage.setItem("currentPage", nextPage.toString());

    (<HTMLButtonElement>document.getElementById("previousBtn")).disabled = !isButtonReq("previous");
    (<HTMLButtonElement>document.getElementById("nextBtn")).disabled = !isButtonReq("next");
}