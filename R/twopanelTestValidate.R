# Validate a two-panel test by calculating sens and spec
# test consists of two panels 1 and 2, corresponding to arbitrary real variable levels 1 and 2
# Step 1 is to determine panel score using each panel (call for state 1 is from panel 1 criteria and markers, etc.)
# Step 2 is to determine calls for sample state where 2 = score of 1 for both panels OR only panel 2; 1 = score of 1 for ONLY panel 1; 0 = otherwise
# Ideally isolate two-panel tests with sens/spec at least 0.8 or higher...

twopanelTestValidate <- function(betaset,panel1set,panel2set,
                                 refvar,level1var,level2var,
                                 betathreshold1=0.5,betathreshold2=0.5,probecount1=1,probecount2=1){
# Dependencies: (none)

# variables:
# betaset = matrix of methylation measures for samples (rows) by markers (columns)
# panel1set = list of marker panels for determining state 1 or 2, where panels are designated "marker1id;marker2id;marker3id" etc.
# panel2set = list as in panel1set for determining state 2
# refvar = reference variable vector (actual sample states) of length ncol(betaset) with three states including level1var and level2var
# level1var = character string for level of state 1 in refvar
# level2var = character string as in level1var for state 2 in refvar
# betathreshold1 = measurement cutoff for sample to be scored 1 in panel 1 test (>=threshold => score of 1)
# betathreshold2 = measurement cutoff as in betathreshold1 for panel 2 test
# probecount1 = minimum number of probes needed to meet betathreshold1 to be called 1 in panel 1 test
# probecount2 = min probe number as in probecount1 for panel 2 test

if(!length(refvar)==nrow(betaset)){
      print("Choose a valid refvar for all samples in beta value matrix!")
  }

  refvar[!refvar %in% c(level2var,level1var)] <- 0
  refvar[refvar==level1var] <- 1
  refvar[refvar==level2var] <- 2
  refvar <- as.numeric(refvar)

  return.df.twopanel <- matrix(nrow=1,ncol=4)
  colnames(return.df.twopanel) <- c("panel1","panel2","sens","spec")
  print(paste0("Calculating sens/spec of ",length(panel1set)*length(panel2set)," two-panel tests"))
  for(i in 1:length(panel1set)){
    return.set <- matrix(nrow=1,ncol=4)
    for(j in 1:length(panel2set)){
      betaiter <- as.data.frame(betaset[,colnames(betaset) %in% unique(unlist(strsplit(c(panel1set[i],panel2set[j]),";")))])
    
      betaiter$ref <- refvar
    
      betaiter$panel1 <- panel1set[i]
      betaiter$test1panelcall <- 0
      betaiter$test1panelcall <- apply(betaiter[,colnames(betaiter) %in% unlist(strsplit(panel1set[i],";"))],1,function(x) ifelse(length(x[x>=betathreshold1])>=probecount1,1,0))
    
      betaiter$panel2 <- panel2set[j]
      betaiter$test2panelcall <- 0
      betaiter$test2panelcall <- apply(betaiter[,colnames(betaiter) %in% unlist(strsplit(panel2set[j],";"))],1,function(x) ifelse(length(x[x>=betathreshold2])>=probecount2,1,0))
      
      betaiter$panelcall12 <- 0
      betaiter$panelcall12 <- ifelse(betaiter$test2panelcall==1 & betaiter$test1panelcall==1, 2,ifelse(betaiter$test2panelcall==1,2,ifelse(betaiter$test2panelcall==0 & betaiter$test1panelcall==1,1,0)))
      
      betaiter$sens <- nrow(betaiter[betaiter$panelcall12==1 & betaiter$ref==1 | betaiter$panelcall12==2 & betaiter$ref==2,])/length(refvar[refvar %in% c(1,2)])
      betaiter$spec <- nrow(betaiter[betaiter$test1panelcall==0 & betaiter$ref==0| betaiter$test2panelcall==0 & betaiter$ref==0,])/length(refvar[refvar==0])

      if(j==1){
        return.set <- as.matrix(data.frame(betaiter[1,]$panel1,betaiter[1,]$panel2,
                                  betaiter[1,]$sens,betaiter[1,]$spec))
      } else{
        add.set <- as.matrix(data.frame(betaiter[1,]$panel1,betaiter[1,]$panel2,
                                        betaiter[1,]$sens,betaiter[1,]$spec))
        
        return.set <- rbind(return.set,add.set)
      }
    
    
    }
    if(i==1){
      return.df.twopanel <- return.set
    } else{
      return.df.twopanel <- rbind(return.df.twopanel,return.set)
    }
    colnames(return.df.twopanel) <- c("panel1","panel2","sens","spec")
  }
  print("...Done!")
  print(paste0("Among ",
             length(panel1set)*length(panel2set),
             " two-panel tests, there are ",nrow(betaiter[betaiter$sens>=0.8 & betaiter$spec>=0.8,]),
             " tests with sens and spec >=0.8."))
  return(return.df.twopanel)
}
