https://github.com/jbkunst/highcharter/blob/master/dev/drill-down-ex.R

rm(list = ls())
library("purrr")
library("highcharter")
library("visNetwork")
library("DT")
library("data.table")
library("reshape")
library("dplyr")
library("sqldf")
library("ggplot2")
input <- "D:\\meetup_DSBKK\\segmentation_real\\data\\"


df <- data_frame(
  name = c("Animals", "Fruits", "Cars"),
  y = c(5, 2, 4),
  drilldown = tolower(name)
)

df

hc <- highchart() %>%
  hc_chart(type = "column") %>%
  hc_title(text = "Basic drilldown") %>%
  hc_xAxis(type = "category") %>%
  hc_legend(enabled = FALSE) %>%
  hc_plotOptions(
    series = list(
      boderWidth = 0,
      dataLabels = list(enabled = TRUE)
    )
  ) %>%
  hc_add_series(
    data = df,
    name = "Things",
    colorByPoint = TRUE
  )


dfan <- data_frame(
  name = c("Cats", "Dogs", "Cows", "Sheep", "Pigs"),
  value = c(4, 3, 1, 2, 1)
)

dffru <- data_frame(
  name = c("Apple", "Organes"),
  value = c(4, 2)
)

dfcar <- data_frame(
  name = c("Toyota", "Opel", "Volkswagen"),
  value = c(4, 2, 2)
)

hc <- hc %>%
  hc_drilldown(
    allowPointDrilldown = TRUE,
    series = list(
      list(
        id = "animals",
        data = list_parse2(dfan)
      ),
      list(
        id = "fruits",
        data = list_parse2(dffru)
      ),
      list(
        id = "cars",
        data = list_parse2(dfcar)
      )
    )
  )

hc








df <- data_frame(
  name = c("Animals", "Fruits", "Cars"),
  y = c(5, 2, 4),
  drilldown = tolower(name)
)

df <- fread(paste0(input,"buy_notbuy.csv"))
df <- df %>% mutate(total=sum(nb_customer),
              pct_share = round(100 * nb_customer / total )) %>% 
            rename(name=type,y=pct_share) %>% mutate(drilldown = tolower(name)) %>%
            select(name,y,drilldown)

hc <- highchart() %>%
  hc_chart(type = "column") %>%
  hc_title(text = "Basic drilldown") %>%
  hc_xAxis(type = "category") %>%
  hc_legend(enabled = FALSE) %>%
  hc_plotOptions(
    series = list(
      boderWidth = 0,
      dataLabels = list(enabled = TRUE)
    )
  ) %>%
  hc_add_series(
    data = df,
    name = "Things",
    colorByPoint = TRUE
  )

hc

dfan <- data_frame(
  name = c("Cats", "Dogs", "Cows", "Sheep", "Pigs"),
  value = c(4, 3, 1, 2, 1)
)


dfan <- fread(paste0(input,"mono_multi_item.csv"))
dfan <- dfan %>% mutate(total=sum(nb_customer),
                    pct_share = round(100 * nb_customer / total )) %>% 
  rename(name=type_b,value=pct_share) %>% mutate(drilldown = tolower(name)) %>%
  select(name,value)


hc <- hc %>%
  hc_drilldown(
    allowPointDrilldown = TRUE,
    series = list(
      list(
        id = "buy",
        data = list_parse2(dfan)

    )
  )
  )

hc


########
# Most bought product 
########

http://www.cookbook-r.com/Graphs/Bar_and_line_graphs_(ggplot2)/
  
most_bought <- fread(paste0(input,"most_bought_item.csv"))
most_bought <- sqldf("select * from most_bought order by nb_times desc limit 10 ")

ggplot(data=most_bought, aes(x=product, y=nb_times )) +
  geom_bar(colour="black", stat="identity") + 
  ggtitle("top 10 most bought product") +    theme(axis.text.x = element_text(angle = 35, hjust = 1))

##########
# Viznetwork
#############

http://datastorm-open.github.io/visNetwork/

#example
require(visNetwork, quietly = TRUE)
# minimal example
nodes <- data.frame(id = 1:3)
edges <- data.frame(from = c(1,2), to = c(1,3))
visNetwork(nodes, edges, width = "100%")  
  
  
application <- "twentyfour_seven"
category_lift <- fread(paste0(input,'category_lift.csv'),encoding='UTF-8')
category_lift<-data.frame(category_lift)
#filter
category_lift <- filter(category_lift, nb_cus_cross > 5)

nodes <- data.frame(id = unique(c(category_lift$enter_cat,category_lift$following_cat)))
edges <- data.frame(from = category_lift$enter_cat,
                    to=category_lift$following_cat
)


visNetwork(nodes, edges, width = "100%")  



application <- "twentyfour_seven"
category_lift <- fread(paste0(input,'category_lift.csv'),encoding='UTF-8')
category_lift<-data.frame(category_lift)
#filter
category_lift <- filter(category_lift, nb_cus_cross > 5)



#get all node names
all_node_names <- unique(c(category_lift$enter_cat,category_lift$following_cat))
#extract lev1
all_node_names_lev1 <- data.frame(node = all_node_names,
                                  lev1=sapply(all_node_names, 
                                              FUN = function(x) strsplit(x, ' > ')[[1]][1]))


colors = c('#996633', 
           '#adad85' , 
           '#ff33cc', 
           '#000066', 
           '#ff0000', 
           '#b31aff', 
           '#ff9933', 
           '#ccffcc', 
           '#33cc33', 
           '#ffcc66') 







#make color reference data frame
unique_lev1 <- data.frame(lev1 = unique(all_node_names_lev1$lev1)) %>% arrange(lev1)
unique_lev1$color <- colors[1:dim(unique_lev1)[1]]

#get enter cat to loop thru
enter_nodes <- unique(category_lift$enter_cat)
enter_nodes_lev1 <-unique(sapply(enter_nodes, FUN = function(x) strsplit(x, ' > ')[[1]][1]))

#filter by category
#category_lift_one <- sqldf(paste0("select * from category_lift where enter_cat like '%",i,"%'"))
category_lift_one <- category_lift



#make all node names just for this enter category
node_names <- unique(c(category_lift_one$enter_cat,category_lift_one$following_cat))
node_names_lev1 <- data.frame(node = node_names,
                              lev1=sapply(node_names, 
                                          FUN = function(x) strsplit(x, ' > ')[[1]][1]))


#join with color
node_names_lev1 <- sqldf("select 
                         node_names_lev1.node,
                         node_names_lev1.lev1,
                         unique_lev1.color 
                         from node_names_lev1
                         left join unique_lev1 on
                         node_names_lev1.lev1 = unique_lev1.lev1
                         ")

#set nodes
nodes <- data.frame(id=node_names_lev1$node,
                    font.size=28,
                    color=node_names_lev1$color,
                    group = node_names_lev1$lev1,
                    shape='dot'
)
#set legend nodes
lnode_names <- node_names_lev1[!duplicated(node_names_lev1$lev1),c('lev1','color')]
lnodes <- data.frame(label = lnode_names$lev1,
                     shape = c( "dot"), color =lnode_names$color,
                     title = "Level 1 Category",
                     size = 15)

#set edges
edges <- data.frame(from = category_lift_one$enter_cat,
                    to=category_lift_one$following_cat,
                    value = category_lift_one$lift,
                    label = category_lift_one$lift,
                    arrows = 'to'
)

#graph

v<-visNetwork(nodes, edges, height=700, width='100%',main =paste(application,"Category Association")) %>% 
  visOptions(highlightNearest = TRUE, nodesIdSelection = FALSE) %>% 
  visPhysics(solver = "forceAtlas2Based", 
             forceAtlas2Based = list(gravitationalConstant = -500),
             maxVelocity=0) %>%
  visInteraction(navigationButtons = TRUE) %>% 
  visLegend(useGroups=FALSE,addNodes=lnodes) %>%
  visOptions(selectedBy=list(variable="group"))
#v



nodes_modified <- nodes %>% select(id) %>%rename(label=id) %>% mutate(id=1,
                                                                      id=cumsum(id)) %>% select(id,label)

edges_modified <- edges %>% 
  select(from,to,value) %>% rename(aha=from,oho=to,Weight=value)

edges_modified <- sqldf("select 
                        b.id as Source,
                        c.id as Target,
                        a.Weight
                        
                        from edges_modified a
                        left join nodes_modified b on a.aha = b.label
                        left join nodes_modified c on a.oho = c.label")


fwrite(edges_modified,paste0(input,'edges.csv'))
fwrite(nodes_modified,paste0(input,'nodes.csv'))




from_gephy <- fread(paste0(input,'from_gephy.csv'),encoding='UTF-8')
from_gephy <- data.frame(from_gephy)
from_gephy <- from_gephy %>% select(Label,modularity_class)


modularity_class = unique(from_gephy$modularity)

colors <- data.frame(modularity_class = unique(from_gephy$modularity),
                     color=c('#996633', 
                             '#adad85' , 
                             '#ff33cc', 
                             '#000066', 
                             '#ff0000', 
                             '#b31aff')
)

#join the information 
nodes <- sqldf("select 
               a.`id`,
               a.`font.size`,
               c.color as color , 
               b.modularity_class as `group` ,
               a.shape
               from nodes a 
               left join from_gephy b on a.`id` = b.Label
               left join colors c on c.modularity_class = b.modularity_class 
               ")

nodes$id <- sapply(as.character(node_names), 
                   FUN = function(x) strsplit(x, ' > ')[[1]][2]) 

edges$from <- sapply(as.character(edges$from), 
                     FUN = function(x) strsplit(x, ' > ')[[1]][2])  

edges$to <- sapply(as.character(edges$to), 
                   FUN = function(x) strsplit(x, ' > ')[[1]][2])  


lnodes <- sqldf("select `group` as label ,
                shape , 
                color , 
                'category level 1' as title ,
                15 as size
                from nodes 
                group by 1 ,2,3,4,5
                ")


v_modified <-visNetwork(nodes, edges, height=700, width='100%',main =paste(application,"Category Association")) %>% 
  visOptions(highlightNearest = TRUE, nodesIdSelection = FALSE) %>% 
  visPhysics(solver = "forceAtlas2Based", 
             forceAtlas2Based = list(gravitationalConstant = -500),
             maxVelocity=0) %>%
  visInteraction(navigationButtons = TRUE) %>% 
  visLegend(useGroups=FALSE,addNodes=lnodes) %>%
  visOptions(selectedBy=list(variable="group"))


v_modified

nodes_twentyfour <- nodes %>%   select(id,group) %>% arrange(group) %>% mutate(group=as.character(group))

datatable(nodes_twentyfour ,
          class = 'cell-border stripe',
          filter = 'bottom' ,
          colnames = c("Category","group"),
          rownames = FALSE,
          options =
            list(
              pageLength = 10,
              initComplete = JS(
                "function(settings, json) {",
                "$(this.api().table().header()).css({
                'background-color': '#007acc',
                'color': '#ffffff',
                'font-size' : '12px'
                });",
                "}")
            )
            )
