#' Generate bootstrap plots
#'
#' \code{generate.bootstrap.plots} takes a genelist and a single cell type transcriptome dataset
#' and generates plots which show how the expression of the genes in the list compares to those
#' in randomly generated gene lists
#'
#' @param sct_data List generated using \code{\link{read_celltype_data}}
#' @param mouse.hits Array of MGI gene symbols containing the target gene list.
#' @param mouse.bg Array of MGI gene symbols containing the background gene list.
#' @param reps Number of random gene lists to generate (default=100 but should be over 10000 for publication quality results)
#' @param sub a logical indicating whether to analyse sub-cell type annotations (TRUE) or cell-type annotations (FALSE). Default is FALSE.
#' @param full_results The full output of \code{\link{bootstrap.enrichment.test}} for the same genelist
#' @param listFileName String used as the root for files saved using this function
#' @return Saves a set of pdf files containing graphs. These will be saved with the filename adjusted using the
#' value of listFileName. The files are saved into the 'BootstrapPlot' folder. The files start with one of the following:
#' \itemize{
#'   \item \code{qqplot_noText}: sorts the gene list according to how enriched it is in the relevant celltype. Plots the value in the target list against the mean value in the bootstrapped lists.
#'   \item \code{qqplot_wtGSym}: as above but labels the gene symbols for the highest expressed genes.
#'   \item \code{bootDists}: rather than just showing the mean of the bootstrapped lists, a boxplot shows the distribution of values
#'   \item \code{bootDists_LOG}: shows the bootstrapped distributions with the y-axis shown on a log scale
#' }
#'
#'
#' @examples
#' # Load the single cell data
#' data(celltype_data)
#'
#' # Set the parameters for the analysis
#' reps=100 # <- Use 100 bootstrap lists so it runs quickly, for publishable analysis use >10000
#' subCellStatus=0 # <- Use subcell level annotations (i.e. Interneuron type 3)
#' if(subCellStatus==1){subCellStatus=TRUE;cellTag="SubCells"}
#' if(subCellStatus==0){subCellStatus=FALSE;cellTag="FullCells"}
#'
#' # Load the gene list and get human orthologs
#' data("example_genelist")
#' data("mouse_to_human_homologs")
#' m2h = unique(mouse_to_human_homologs[,c("HGNC.symbol","MGI.symbol")])
#' mouse.hits = unique(m2h[m2h$HGNC.symbol %in% example_genelist,"MGI.symbol"])
#' mouse.bg  = unique(setdiff(m2h$MGI.symbol,mouse.hits))
#'
#' # Bootstrap significance testing, without controlling for transcript length and GC content
#' full_results = bootstrap.enrichment.test(sct_data=celltype_data,mouse.hits=mouse.hits,
#'      mouse.bg=mouse.bg,reps=reps,sub=subCellStatus)
#'
#' generate.bootstrap.plots(sct_data=celltype_data,mouse.hits=mouse.hits, mouse.bg=mouse.bg,
#'      reps=reps,sub=FALSE,full_results=full_results,listFileName="Example")
#' @export
#' @import ggplot2
#' @importFrom reshape2 melt
# @import plyr
generate.bootstrap.plots.for.transcriptome <- function(sct_data,tt,thresh,annotLevel=1,reps,full_results=NA,listFileName="",showGNameThresh=25){
    require(cowplot)
    # Check the arguments
    correct_length = length(full_results)==5
    required_names = c("joint_results","hit.cells.up","hit.cells.down","bootstrap_data.up","bootstrap_data.down")
    all_required_names = sum(names(full_results) %in% required_names)==5
    if(!correct_length | !all_required_names){stop("ERROR: full_results is not valid output from the ewce_expression_data function. This function only takes data generated from transcriptome analyses.")}
    if(thresh>(2*dim(tt)[1])){stop("ERROR: threshold length must not be more than twice the length of the top table")}
    # Check top table has an MGI.symbol column
    if(!sum(colnames(tt)=="MGI.symbol")==1){stop("ERROR: top table (tt) must have 'MGI.symbol' column")}

    for(dirS in c("Up","Down")){
        a = full_results$joint_results
        results = a[as.character(a$Direction)==dirS,]

        # Drop genes lacking expression data
        if(dirS=="Up"){tt=tt[order(tt$t,decreasing=TRUE),]}
        if(dirS=="Down"){tt=tt[order(tt$t,decreasing=FALSE),]}
        mouse.hits = unique(tt$MGI.symbol[1:thresh])
        mouse.hits = mouse.hits[mouse.hits %in% rownames(sct_data[[1]]$specificity)]
        mouse.bg = unique(tt$MGI.symbol)
        mouse.bg = mouse.bg[!mouse.bg %in% mouse.hits]
        mouse.bg = mouse.bg[mouse.bg %in% rownames(sct_data[[1]]$specificity)]

        # Get expression data of bootstrapped genes
        exp_mats = get_bootstrap_matrix(nReps=reps,mouse.hits=mouse.hits,mouse.bg=mouse.bg,cell_types=as.character(unique(a$CellType)),sct_data=sct_data,annotLevel=annotLevel)
        
        # Get expression levels of the hit genes
        hit.exp = sct_data[[annotLevel]]$specificity[mouse.hits,]	#cell.list.exp(mouse.hits)

        #print(hit.exp)

        graph_theme = theme_bw(base_size = 12, base_family = "Helvetica") +
            theme(panel.grid.major = element_line(size = .5, color = "grey"),
                  axis.line = element_line(size=.7, color = "black"),legend.position = c(0.75, 0.7), text = element_text(size=18),
                  axis.title.x = element_text(vjust = -0.35), axis.title.y = element_text(vjust = 0.6)) + theme(legend.title=element_blank())#+ylim(c(1,100))

        if (!file.exists("BootstrapPlots")){
            dir.create(file.path(getwd(), "BootstrapPlots"))
        }

        tag = sprintf("thresh%s__dir%s",thresh,dirS)

        # Plot the QQ plots
        for(cc in as.character(unique(a$CellType))){
            #cc = "Vascular and Leptomeningeal Cells"
            #mean_boot_exp = apply(exp_mats[[cc]],2,mean)
            #mean_boot_exp
            #cc = "Pericytes"
            mean_boot_exp = apply(exp_mats[[cc]],2,mean)
            #mean_boot_exp
            
            
            hit_exp = sort(hit.exp[,cc])
            hit_exp_names = rownames(hit.exp)[order(hit.exp[,cc])]#names(hit_exp)
            dat = data.frame(boot=mean_boot_exp,hit=hit_exp,Gnames=hit_exp_names)
            dat$hit = dat$hit*100
            dat$boot = dat$boot*100
            maxHit = max(dat$hit)
            maxX = max(dat$boot)+0.1*max(dat$boot)

                        basic_graph = ggplot(dat,aes_string(x="boot",y="hit"))+geom_point(size=1)+xlab("Mean Bootstrap Expression")+ylab("Expression in cell type (%)\n") + graph_theme +
                geom_abline(intercept = 0, slope = 1, colour = "red")


            # Plot without text
            pdf(sprintf("BootstrapPlots/qqplot_noText_%s____%s____%s.pdf",tag,listFileName,cc),width=3.5,height=3.5)
            print(basic_graph+ggtitle(cc))
            dev.off()

            # If a gene has over 25% of it's expression proportion in a celltype, then list the genename
            dat$symLab = ifelse(dat$hit>showGNameThresh,sprintf("  %s", dat$Gnames),'')

            #basic_graph = ggplot(dat,aes(x=boot,y=hit))+geom_point(size=2)+xlab("Mean Bootstrap Expression")+ylab("Expression in cell type (%)\n") + graph_theme +
            basic_graph = ggplot(dat,aes_string(x="boot",y="hit"))+geom_point(size=2)+xlab("Mean Bootstrap Expression")+ylab("Expression in cell type (%)\n") + graph_theme +
                geom_abline(intercept = 0, slope = 1, colour = "red")

            # Plot with bootstrap distribution
            melt_boot = melt(exp_mats[[cc]])
            colnames(melt_boot) = c("Rep","Pos","Exp")
            actVals = data.frame(pos=as.factor(1:length(hit_exp)),vals=hit_exp)

            # Plot with LOG bootstrap distribution
            # - First get the ordered gene names
            rownames(dat)=dat$Gnames
            datOrdered = data.frame(GSym=rownames(dat),Pos=1:dim(dat)[1])

            # - Arrange the data frame for plotting
            melt_boot = melt(exp_mats[[cc]])
            colnames(melt_boot) = c("Rep","Pos","Exp")
            melt_boot$Exp = melt_boot$Exp*100
            melt_boot = merge(melt_boot,datOrdered,by="Pos")
            melt_boot$GSym = factor(as.character(melt_boot$GSym),levels=as.character(datOrdered$GSym))

            # - Prepare the values of the list genes to be plotted as red dots
            actVals = data.frame(Pos=as.factor(1:length(hit_exp)),vals=hit_exp*100)
            actVals = merge(actVals,datOrdered,by="Pos")
            actVals$GSym = factor(as.character(actVals$GSym),levels=as.character(datOrdered$GSym))

            # Convert gene names from mouse to human
            o2o = One2One::ortholog_data_Mouse_Human$orthologs_one2one
            rownames(o2o) = One2One::ortholog_data_Mouse_Human$orthologs_one2one$mouse.symbol
            
            # - Determine whether changes are significant
            p = rep(1,max(melt_boot$Pos))
            for(i in 1:max(melt_boot$Pos)){
                p[i] = sum(actVals[actVals$Pos==i,"vals"]<melt_boot[melt_boot$Pos==i,"Exp"])/length(melt_boot[melt_boot$Pos==i,"Exp"])
            }
            ast = rep("*",max(melt_boot$Pos))
            ast[p>0.05] = ""
            actVals = cbind(actVals[order(actVals$Pos),],ast)
            # - Plot the graph!
            wd = 1+length(unique(melt_boot[,4]))*0.2
            pdf(sprintf("BootstrapPlots/bootDists_LOG_%s___%s____%s.pdf",tag,listFileName,cc),width=wd,height=4)
            #png(sprintf("BootstrapPlots/bootDists_LOG_%s___%s____%s.png",tag,listFileName,cc),width=wd*100,height=4*100)
            lvls = levels(melt_boot$GSym)
            lvls_HGNC = o2o[lvls,]$human.symbol
            melt_boot$GSym = as.character(melt_boot$GSym)
            melt_boot$GSym = o2o[as.character(melt_boot$GSym),]$human.symbol
            melt_boot$GSym = factor(melt_boot$GSym,levels=rev(lvls_HGNC))
            actVals$GSym = o2o[as.character(actVals$GSym),]$human.symbol
            #melt_boot$GSym = factor(melt_boot$GSym,levels=rev(levels(melt_boot$GSym)))
            print(ggplot(melt_boot)+geom_boxplot(aes_string(x="GSym",y="Exp"),outlier.size=0)+graph_theme+
                      theme(axis.text.x = element_text(angle = 90, hjust = 1))+
                      geom_point(aes_string(x="GSym",y="vals"),col="red",data=actVals)+
                      geom_text(aes_string(x="GSym",y="vals",label="ast"),colour="black",col="black",data=actVals)+
                      ylab("Cell type specificity\n")+
                      xlab("Most specific --> Least specific")+scale_y_log10(limits=c(1,100)))

            dev.off()
        }
    }
}
