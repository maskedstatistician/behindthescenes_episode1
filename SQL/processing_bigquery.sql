#how many customer has bought and how many never bought  
select
customer , 
flag_purchase , 
nb_items , 
case 
when nb_items = 0 then 'Never' 
when nb_items = 1 then 'Mono'  
else 'Multi' end as flag_mono_multi 
from ( 
	select 
	a.customer as customer,
	case when b.customer_b is not null then 'Buy' else 'Never_Buy' end as  flag_purchase, 
	coalesce(cast(nb_items as integer),0) as nb_items 
	from twentyfour_seven.dim_customer a 
	left join
	(
	SELECT customer as customer_b,
	count(*) as nb_items
	FROM twentyfour_seven.tr_product 
	group by 1 ) b  on a.customer = b.customer_b 
	limit 100 
) temp  ;



bq rm -f patrick.analysis_segmentation_15
table_destination=patrick.analysis_segmentation_15
query="
select
customer , 
flag_purchase , 
nb_items , 
case 
when nb_items = 0 then 'Never' 
when nb_items = 1 then 'Mono'  
else 'Multi' end as flag_mono_multi 
from ( 
select 
a.customer as customer,
case when b.customer_b is not null then 'Buy' else 'Never_Buy' end as  flag_purchase, 
coalesce(cast(nb_items as integer),0) as nb_items 
from twentyfour_seven.dim_customer a 
left join
(
SELECT customer as customer_b,
count(*) as nb_items
FROM twentyfour_seven.tr_product 
group by 1 ) b  on a.customer = b.customer_b 
) temp  ;
"
bq query --allow_large_results --replace --noflatten_results --destination_table="$table_destination" "$query"


#how many purchase how many haven't purchase 
select  
flag_purchase as type ,
count(*) as nb_customer,
from patrick.analysis_segmentation_15 
group by 1 


#have they purchase or not 
select 
flag_purchase  as type,
flag_mono_multi as type_b,
count(*) as nb_customer 
from patrick.analysis_segmentation_15 
where nb_items > 0 
group by 1 ,2


#most purchase item 
select
product , 
count(*) as nb_times
from twentyfour_seven.tr_product
group by 1
order by 2 desc 

#here we start the association of products 

#get deviceID from august
bq rm -f patrick.analysis_segmentation_1
table_destination=patrick.analysis_segmentation_1
query="
select *
,concat('PRODUCT' ,' > ' , upper(product)) as concat_lev
from twentyfour_seven.tr_product 
"
bq query --allow_large_results --replace --noflatten_results --destination_table="$table_destination" "$query"


#create the relations
bq rm -f patrick.analysis_segmentation_7
table_destination=patrick.analysis_segmentation_7
query="
select temp.* 
from (
select 
* 
,ROW_NUMBER() OVER(PARTITION BY customer order by customer) the_rank
from 
patrick.analysis_segmentation_1
) temp
"
bq query --use_legacy_sql=false --allow_large_results --replace --noflatten_results --destination_table="$table_destination" "$query"



#construct the combination from A to B 
bq rm -f patrick.analysis_segmentation_8
table_destination=patrick.analysis_segmentation_8
query="
select * 
from ( 
select
b.the_rank 
,a.customer  
,a.concat_lev as category_entry 
,b.concat_lev as category_following 
from patrick.analysis_segmentation_7 a 
left join patrick.analysis_segmentation_7 b on 
a.customer = b.customer 
and a.the_rank = b.the_rank - 1 )
where the_rank is not null 
"
bq query --use_legacy_sql=false --allow_large_results --replace --noflatten_results --destination_table="$table_destination" "$query"


################
# The Counting #
################

#Aggregate for nb_cross_customer : category_nb_cross_customers
bq rm -f patrick.analysis_segmentation_9
table_destination=patrick.analysis_segmentation_9
query="
select
category_entry,
category_following,
count(distinct customer) as nb_cross_customer
from patrick.analysis_segmentation_8
group by
category_entry,
category_following
"
bq query --use_legacy_sql=false --allow_large_results --replace --noflatten_results --destination_table="$table_destination" "$query"


#Aggregate for nb_entry_customer

bq rm -f patrick.analysis_segmentation_10
table_destination=patrick.analysis_segmentation_10
query="
select
category_entry,
count(distinct customer) as nb_entry_customer
from patrick.analysis_segmentation_8
group by
category_entry
"
bq query --use_legacy_sql=false --allow_large_results --replace --noflatten_results --destination_table="$table_destination" "$query"


#Aggregate for nb_following_customer
bq rm -f patrick.analysis_segmentation_11
table_destination=patrick.analysis_segmentation_11
query="
select
category_following,
count(distinct customer) as nb_following_customer
from patrick.analysis_segmentation_8
group by
category_following
"
bq query --use_legacy_sql=false --allow_large_results --replace --noflatten_results --destination_table="$table_destination" "$query"


#Aggregate for nb_all_customers

bq rm -f patrick.analysis_segmentation_12
table_destination=patrick.analysis_segmentation_12
query="
select
count(distinct customer) as nb_all_customer
from patrick.analysis_segmentation_8
"
bq query --use_legacy_sql=false --allow_large_results --replace --noflatten_results --destination_table="$table_destination" "$query"

#join all the counting tables

bq rm -f patrick.analysis_segmentation_13
table_destination=patrick.analysis_segmentation_13
query="
select
category_nb_cross_customers.category_entry,
category_nb_cross_customers.category_following,
category_nb_cross_customers.nb_cross_customer,
category_nb_entry_customers.nb_entry_customer,
category_nb_following_customers.nb_following_customer,
category_nb_all_customers.nb_all_customer
from patrick.analysis_segmentation_10 as category_nb_entry_customers
inner join patrick.analysis_segmentation_9 as category_nb_cross_customers
on category_nb_entry_customers.category_entry = category_nb_cross_customers.category_entry
inner join patrick.analysis_segmentation_11 as category_nb_following_customers
on category_nb_cross_customers.category_following = category_nb_following_customers.category_following
cross join patrick.analysis_segmentation_12 as category_nb_all_customers
"
bq query --use_legacy_sql=false --allow_large_results --replace --noflatten_results --destination_table="$table_destination" "$query"


#add lift
bq rm -f patrick.analysis_segmentation_14
table_destination=patrick.analysis_segmentation_14
query="
select * from
(select
category_entry as enter_cat,
category_following as following_cat,
nb_cross_customer as nb_cus_cross,
nb_entry_customer as nb_cus_enter,
nb_following_customer as nb_cus_follow,
nb_all_customer as nb_customer_tot,
round(nb_cross_customer / nb_entry_customer * 100) as confidence , 
round(nb_following_customer / nb_all_customer * 100)  as expected,
round(( nb_cross_customer / nb_entry_customer ) / (nb_following_customer / nb_all_customer),1) as lift 
from (
select * from patrick.analysis_segmentation_13
where nb_entry_customer > 1) A) B
where lift >= 1
"
bq query --use_legacy_sql=false --allow_large_results --replace --noflatten_results --destination_table="$table_destination" "$query"


#category lift export 
select * from patrick.analysis_segmentation_14
