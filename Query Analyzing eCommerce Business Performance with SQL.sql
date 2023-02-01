--Annual Customer Activity Growth Analysis
--Syntax average number of monthly active customers for each year

Select 
	Distinct date_part('year', t2.order_purchase_timestamp) as years,
    Count(Distinct t1.customer_id)/Count(Distinct date_part('month',order_purchase_timestamp)) as MAU
From customers_dataset t1
Join orders_dataset t2 On t1.customer_id = t2.customer_id
Group By 1
Order By 1;

--Syntax of the number of new customers in each year

Select 
	Distinct date_part('year', t2.order_purchase_timestamp) as years,
    Count(Distinct t1.customer_unique_id) as total_new_customers
From customers_dataset t1
Join orders_dataset t2 On t1.customer_id = t2.customer_id
Group By 1
Order By 1;

--Syntax the number of customers who make purchases more than once (repeat orders) in each year

With
tht as 
(
	Select 
		date_part('year', t2.order_purchase_timestamp) as Years,
        t1.customer_unique_id as customer, 
  		Count(t2.order_id) as total_order
    From customers_dataset t1
    Join orders_dataset t2 On t1.customer_id = t2.customer_id
    Group by 1, 2
)

Select 
	Distinct Years, 
	Count(customer) as total_customer_repeat_order
From tht
Where total_order > 1
Group By 1
Order By 1;

--Syntax of the average number of orders placed by customers for each year

With
tht2 as 
(
	Select 
		date_part('year', order_purchase_timestamp) as years, 
    	customer_unique_id as customer, 
    	Count(order_id) as total_order
    From customers_dataset t1
    Join orders_dataset t2 On t1.customer_id = t2.customer_id
    Group By 1, 2
    Order By 1
)

Select 
	Distinct years, 
	round(avg(total_order),2) as rata_rata_order
From tht2
Group By 1
Order By 1

--Combining four syntax into one table

With
tht as 
(
	Select 
		date_part('year', t2.order_purchase_timestamp) as Years,
        t1.customer_unique_id as customer, 
  		Count(t2.order_id) as total_order
    From customers_dataset t1
    Join orders_dataset t2 On t1.customer_id = t2.customer_id
    Group by 1, 2
),
			
tht2 as 
(
	Select 
		date_part('year', order_purchase_timestamp) as years, 
        customer_unique_id as customer, 
        Count(order_id) as total_order
    From customers_dataset t1
    Join orders_dataset t2 On t1.customer_id = t2.customer_id
    Group By 1, 2
    Order By 1
),		
  
mau_year as 
(
	Select 
		Distinct date_part('year', t2.order_purchase_timestamp) as years,
        Count(Distinct t1.customer_id)/Count(Distinct date_part('month',order_purchase_timestamp)) as MAU
	From customers_dataset t1
	Join orders_dataset t2 On t1.customer_id = t2.customer_id
	Group By 1
	Order By 1
),

new_customer as 
(
	Select 
		Distinct date_part('year', t2.order_purchase_timestamp) as years,
        Count(Distinct t1.customer_unique_id) as total_new_customers
	From customers_dataset t1
	Join orders_dataset t2 On t1.customer_id = t2.customer_id
	Group By 1
	Order By 1
),
				 
repeat_order as 
(
	Select 
		Distinct Years, 
		Count(customer) as total_customer_repeat_order
	From tht
	Where total_order > 1
	Group By 1
	Order By 1
),
				
avg_order as 
(
	Select 
		Distinct years, 
		round(avg(total_order),2) as rata_rata_order
	From tht2
	Group By 1
	Order By 1
)

Select 
	mau_y.years,
	mau_y.mau,
	new_c.total_new_customers,
	repeat_o.total_customer_repeat_order,
	avg_o.rata_rata_order
From mau_year mau_y
Join new_customer new_c ON mau_y.years = new_c.years
Join repeat_order repeat_o ON mau_y.years = repeat_o.years
Join avg_order avg_o ON mau_y.years = avg_o.years
Order by 1;

--Annual Product Category Quality Analysis
--Syntax containing total company revenue information for each year

Create table revenue_per_year as
	With ro as
	(
		Select
			order_id,
	        sum(price + freight_value) as revenue_per_order
	    From order_items_dataset
	    Group by 1
	)

	Select 
		date_part('year', o1.order_purchase_timestamp) as years,
    	sum(ro.revenue_per_order) as revenue
	From ro
	Join orders_dataset o1 on ro.order_id = o1.order_id
	Where o1.order_status = 'delivered'
	Group by 1;

--Syntax containing information on the total number of cancel orders for each year

Create table order_canceled_per_years as
	Select
		date_part('year', order_purchase_timestamp) as years,
        count(order_id) as total_order_canceled
    From orders_dataset
    Where order_status = 'canceled'
    Group by 1
    Order by 1;

--Syntax containing the name of the product category that provided the highest total revenue for each year

Create table top_product_revenue as
	with rk as 
	(
		Select
			date_part('year', o2.order_purchase_timestamp) as years,
	        p1.product_category_name,
	        sum(o1.price + o1.freight_value) as revenue,
	        rank() over(partition by date_part('year', o2.order_purchase_timestamp)
					 order by sum(o1.price + o1.freight_value)Desc) as ranking
	    From order_items_dataset o1
	    Join orders_dataset o2 on o1.order_id = o2.order_id
	    Join product_dataset p1 on o1.product_id = p1.product_id
	    Where order_status = 'delivered'
	    Group by 1,2
	)
	Select
		years, 
		product_category_name, 
		revenue
 	From rk
	Where ranking = 1;

--Syntax containing the name of the product category that has the highest number of cancel orders for each year

Create table most_canceled_per_year AS
	With rk as 
	(
		Select
			date_part('year', o2.order_purchase_timestamp) as years,
	        p1.product_category_name,
	        Count(o2.order_status) as canceled,
	        rank() over(partition by date_part('year', o2.order_purchase_timestamp)
						order by count(o2.order_status)Desc) as ranking
	    From order_items_dataset o1
	    Join orders_dataset o2 on o1.order_id = o2.order_id
	    Join product_dataset p1 on o1.product_id = p1.product_id
	    Where order_status = 'canceled'
	    Group by 1,2
	)
	Select 
		years, 
		product_category_name, 
		canceled
	From rk
	Where ranking = 1;

--Syntax Combines the information you have obtained into one table view

Select 
	t1.years, 
    t3.product_name, 
    t3.revenue, 
    t1.revenue as total_revenue, 
    t4.product_name,
    t4.total_order_canceled as order_canceled, t2.total_order_canceled
From revenue_per_years t1
Join order_canceled t2 on t1.years = t2.years
Join top_product_revenue t3 on t1.years = t3.years
Join top_product_canceled t4 on t1.years = t4.years
Group by 1, 2, 3, 4, 5, 6, 7
Order by 1;

--Analysis of Annual Payment Type Usage
--Syntax of the number of uses of each payment type in all time sorted from favorite

Select 
	payment_type, 
	count(order_id) as total_order
From order_payments_dataset3
Group by 1
Order by 2 desc;

--Syntax detail information on the amount of use of each payment type for each year

With 
kuy as 
(
	Select
		date_part('year', o1.order_purchase_timestamp) as years,
        o2.payment_type,
	    count(o1.order_id) as used
    From orders_dataset o1
    Join order_payments_dataset o2 on o1.order_id = o2.order_id
    Group by 1, 2
    Order by 1
),

kuy2 as 
(
	Select 
		payment_type,
	    sum(case when years = '2016' then used else 0 end) as year_2016,
	    sum(case when years = '2017' then used else 0 end) as year_2017,
	    sum(case when years = '2018' then used else 0 end) as year_2018
	From kuy
	Group by 1
)

Select *
From kuy2
Order by 2