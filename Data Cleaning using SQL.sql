

use data;
drop table if exists housing_data;
CREATE TABLE housing_data (
    UniqueID INT,
    ParcelID VARCHAR(20),
    LandUse VARCHAR(50),
    PropertyAddress VARCHAR(255),
    SaleDate DATE,
    SalePrice INT NULL,
    LegalReference VARCHAR(50),
    SoldAsVacant VARCHAR(50),
    OwnerName VARCHAR(255),
    OwnerAddress VARCHAR(255),
    Acreage varchar(50),
    TaxDistrict VARCHAR(50),
    LandValue INT NULL,
    BuildingValue INT NULL,
    TotalValue INT NULL,
    YearBuilt INT NULL,
    Bedrooms INT NULL,
    FullBath INT NULL,
    HalfBath INT NULL
);

LOAD DATA INFILE 'housing_data.csv'
INTO TABLE housing_data
FIELDS TERMINATED BY ','  -- This can be optional in your case since there's only one column
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'  -- Assuming the lines are terminated by newline character, adjust if it's different
IGNORE 1 LINES
(UniqueID,ParcelID,LandUse,PropertyAddress,@SaleDate,@SalePrice,LegalReference,SoldAsVacant,OwnerName,OwnerAddress,Acreage,TaxDistrict,@LandValue,@BuildingValue,@TotalValue,@YearBuilt,@Bedrooms,@FullBath,@HalfBath)
SET SaleDate = STR_TO_DATE(@SaleDate, '%M %d, %Y'),
LandValue = NULLIF(@LandValue, ''),
SalePrice = NULLIF(@SalePrice, ''),
    BuildingValue = NULLIF(@BuildingValue, ''),
    TotalValue = NULLIF(@TotalValue, ''),
    YearBuilt = NULLIF(@YearBuilt, ''),
    Bedrooms = NULLIF(@Bedrooms, ''),
    FullBath = NULLIF(@FullBath, ''),
    HalfBath = NULLIF(@HalfBath, '')
;
select * from housing_data;

####populate property address data 

select a.parcelid, a.propertyaddress,b.parcelid, b.propertyaddress,  CASE 
        WHEN a.propertyaddress='' THEN b.propertyaddress else a.propertyaddress
    END AS newclmn from housing_data a join housing_data b on 
a.parcelid=b.parcelid and a.uniqueid!=b.uniqueid where a.propertyaddress='';


UPDATE housing_data a
JOIN housing_data b ON a.parcelid = b.parcelid AND a.uniqueid != b.uniqueid
SET a.propertyaddress = CASE 
                            WHEN a.propertyaddress = '' THEN b.propertyaddress
                            ELSE a.propertyaddress
                         END where a.propertyaddress='';
                         
# Breaking address into individual columns

select substring(propertyaddress,1, instr(propertyaddress,',')-1) from housing_data;

select substring(propertyaddress,instr(propertyaddress,',')+1,length(propertyaddress)) from housing_data;

alter table housing_data add Address varchar(50);

alter table housing_data add City varchar(50);

update housing_data 
set Address = substring(propertyaddress,1, instr(propertyaddress,',')-1);

update housing_data 
set city = substring(propertyaddress,instr(propertyaddress,',')+1,length(propertyaddress));

select address,city,propertyaddress from housing_data;

select substring_index(substring_index(owneraddress,',',2),',',-1) from housing_data;

select owneraddress from housing_data;

alter table housing_data 
add owneradd varchar(50);

alter table housing_data 
add ownercity varchar(50);

alter table housing_data 
add ownerstate varchar(50);

update housing_data
set owneradd=substring_index(owneraddress,',',1);

update housing_data 
set ownercity= substring_index(substring_index(owneraddress,',',2),',',-1);

update housing_data 
set ownerstate=substring_index(owneraddress,',',-1);

select owneradd,ownercity,ownerstate from housing_data;


####change Y and N to Yes and No respectively in SoldAsVacant column

select distinct(soldasvacant) from housing_data;

select soldasvacant,count(soldasvacant) from housing_data group by soldasvacant ;

update housing_data 
set soldasvacant= case when soldasvacant='Y' then 'Yes'
                       when soldasvacant='N' then 'No'
                       else soldasvacant end;
                       
## Remove dupilcates

select * from housing_data;

with cte as(
select uniqueid, row_number() over (partition by parcelid,propertyaddress,saleprice,saledate,legalreference,ownername,owneraddress,buildingvalue,yearbuilt order by uniqueid) as rnum
from housing_data)

delete h from housing_data h join cte c on h.uniqueid=c.uniqueid where rnum>1;


with cte as(
select uniqueid, row_number() over (partition by parcelid,propertyaddress,saleprice,saledate,legalreference,ownername,owneraddress,buildingvalue,yearbuilt order by uniqueid) as rnum
from housing_data)

select * from cte where rnum>1;

# Delete unused columns

alter table housing_data
drop column propertyaddress,
drop column taxdistrict;

select * from housing_data;



