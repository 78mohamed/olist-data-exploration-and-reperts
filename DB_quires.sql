/* before we begin we made 10 queries, the objective of each query is written in a comment above it
 we are team number 3 and the memmbers are :-
 1)Aya Eldouh
 2)Gehad Elkafafi
 3)Hedaya medhat
 4)Hekmat
 5)mohamed mansour

 */





--database we will use

use [Ecommerce]

/*______________________________________________________________________________________________________________________*/
--function takes product id and returns the customer details --
create function GetCustomer (@Pid varchar(50) )
returns table 
as
return 
      ( select p.product_id ,c.* 
	    from [dbo].[Product] p ,[dbo].[Customer] c, [dbo].[Order] o
		where o.product_id = p.product_id and c.customer_id = o.customer_id and p.product_id=@Pid
		)

--test--
select * from  GetCustomer('001b72dfd63e9833e8c02742adf472e3')

/*______________________________________________________________________________________________________________________*/

--1)view / proc(order_id,product id, customer id, total price) total price = frieght + price --
create view OrderDetails
as
select o.order_id,p.product_id,c.customer_id ,( o.freight_value+o.price) as 'total price'
from [dbo].[Product] p ,[dbo].[Customer] c, [dbo].[Order] o
where o.product_id = p.product_id and c.customer_id = o.customer_id

--test--
select * from  OrderDetails


/*______________________________________________________________________________________________________________________*/
 --function returns the  difference between estimated delievry time vs real  in days

  create function get_difference()
 returns table  as return(
 SELECT order_id, 

 (case
 when  order_delivered_customer_date>=order_estimated_delivery_date
 then  'order delivered date was more than estimated by ' +convert(varchar(10), DATEDIFF(day,order_estimated_delivery_date, order_delivered_customer_date))+ ' day(s)'
 
 when  order_delivered_customer_date<order_estimated_delivery_date
 then  'order estimated date was more than delivered by ' +convert(varchar(10),DATEDIFF(day, order_delivered_customer_date,order_estimated_delivery_date))+ ' day(s)'
 else
 'order estimated date was same as delivered'
 end) as 'result'
  FROM [ecommerce].[dbo].[Order] )

go

select * from get_difference()

go



/*______________________________________________________________________________________________________________________*/
-- product table as a view
create view product_view
as
SELECT product_id,category_name,photo_quality,product_weight,
 product_length,product_height,product_width,seller_id
 FROM [ecommerce].[dbo].[Product]

select * from product_view

 go


/*______________________________________________________________________________________________________________________*/

/*do customer from the same city usually use the same payment methode*/
alter proc customer_city @x int=1
as
select * from(
select DENSE_RANK() over(order by c.customer_city) as id,c.customer_id , c.customer_city , o.payment_type 
from [dbo].[Customer] c , [dbo].[Order] o
where c.customer_id = o.customer_id
) as payment_table 
where id = @x

go
--answer some coustomers do
customer_city 13
--other don't
customer_city 10




go


/*______________________________________________________________________________________________________________________*/
--function takes product id and returns the seller details
create function GetSellerDetails(@proid varchar(50))
returns table 
as 
return
(select p.product_id,s.seller_id,s.seller_zip_code,s.seller_city,s.seller_state
from [dbo].[Product] p,[dbo].[Seller] s
where p.seller_id=s.seller_id and p.product_id=@proid 
)

go
select * from GetSellerDetails('0009406fd7479715e4bef61dd91f2462')
go



/*______________________________________________________________________________________________________________________*/
-- Create inline function to get average review score for each product and each category name
create FUNCTION GetAvgScore()
RETURNS TABLE 
AS
RETURN 
		(	SELECT DISTINCT p.product_id, p.category_name,
			AVG(o.review_score) OVER(PARTITION BY p.product_id) AS Average_Product_Score,
			AVG(o.review_score) OVER(PARTITION BY p.category_name) AS Average_Category_Score
			FROM [dbo].[Order] AS o
			INNER JOIN Product AS p
			ON o.product_id = p.product_id
			WHERE p.category_name IS NOT NULL
		)
go
SELECT * 
FROM GetAvgScore()
ORDER BY category_name

go

/*______________________________________________________________________________________________________________________*/
--View to see each product with its photo quality and average review score for the product
CREATE VIEW photoQuality_V_reviewScore
AS
	SELECT DISTINCT p.product_id, p.photo_quality, Average_Product_Score
	FROM Product AS p
	INNER JOIN GetAvgScore() g
	ON p.product_id = g.product_id
	WHERE p.photo_quality IS NOT NULL

SELECT *
FROM photoQuality_V_reviewScore

go

/*______________________________________________________________________________________________________________________*/

--View to see each seller with its review score
create VIEW SellerScores
AS
	SELECT DISTINCT p.seller_id, 
	AVG(Average_Product_Score) OVER(PARTITION BY p.seller_id) AS Average_Score
	FROM Product AS p
	INNER JOIN GetAvgScore() g
	ON p.product_id = g.product_id

go

SELECT * 
FROM SellerScores
ORDER BY Average_Score DESC
go




/*______________________________________________________________________________________________________________________*/
/*using trigger to get new added products or if a product is deleted in two seperate tables using the same trigger*/

create table new_products(
product_id varchar(50),
category_name varchar(50),
seller_id varchar(50),
date_ins date
)
go
create table deleted_products(
product_id varchar(50),
category_name varchar(50),
seller_id varchar(50),
date_del date
)
go


create trigger t1 on [dbo].[Product]
after insert , delete
as
begin
	declare @product_id varchar(50)
	declare @category_name varchar(50)
	declare @seller_id varchar(50)
	select @product_id=product_id , @category_name=category_name , @seller_id=seller_id from inserted
	if(@product_id is not null)
	begin
		insert into new_products values (@product_id,@category_name,@seller_id , GETDATE())
	end
	set @product_id = null
	select @product_id=product_id , @category_name=category_name , @seller_id=seller_id from deleted
	if(@product_id is not null)
	begin
		insert into deleted_products values (@product_id,@category_name,@seller_id , GETDATE())
	end
end

go



insert into [dbo].[Product](product_id ,category_name,seller_id ) 
values('1kk111m2200e' ,'soap' , '5cbbd5a299cab112b7bf23862255e43e' )
go

select * from new_products
select * from deleted_products
go

delete from [dbo].[Product]  where [product_id] = '1kk111m2200e'

go
select * from new_products
select * from deleted_products

go


/*______________________________________________________________________________________________________________________*/
--creating a trigger to prevent droping any table in Ecommerce data.
--if the user tried to alter any table a massage 'Not Allowed' will show up.

go
create trigger t2
on database
for drop_table
as 
  print 'Not Allowed'
   rollback


go

drop table [dbo].[Order]