--Cleaning Data:
--Standardized and cleaned the data to improve usability


Select *
From PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format (DateTime --> Date)


Select SaleDateConverted, CONVERT(Date, SaleDate)
From PortfolioProject.dbo.NashvilleHousing

Update NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

-- Update was not updating SaleDate properly so the following code was implemented:
ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data
Select *
From PortfolioProject.dbo.NashvilleHousing
Where PropertyAddress is NULL
Order by ParcelID

--Implementing a self-join to find cases where the ParcelID field is populated and PropertyAddress field is Null
--Then extrapolate the trend that identical ParcelIDs are correlated with the same PropertyAddress
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing as a
JOIN PortfolioProject.dbo.NashvilleHousing as b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]	--ParcelIDs are the same but not the same row
Where a.PropertyAddress is NULL

--ISNULL() checks to see if a.PropertyAddress is NULL and if so populates the field with b.PropertyAddress,
-- thus extrapolating the data from matching ParcelID fields and updating the original dataset
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing as a
JOIN PortfolioProject.dbo.NashvilleHousing as b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]	--ParcelIDs are the same but not the same row
Where a.PropertyAddress is NULL

--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

--Starting with the PropertyAddress first
Select PropertyAddress
From PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID

-- Extracts the address from PropertyAddress based on the "," delimiter
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address

From PortfolioProject.dbo.NashvilleHousing

-- Appending the seperated address and city columns to the end of the table
ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

--Verifying results of PropertyAddress split
Select *
From PortfolioProject.dbo.NashvilleHousing

--Moving on to splitting the OwnerAddress

Select OwnerAddress
From PortfolioProject.dbo.NashvilleHousing

--Using PARSENAME to extract the address, city, and state information from OwnerAddress:
-- Need to replace the "," with "." within the function
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) --Extracts address
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)--Extracts city
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)--Extracts state
From PortfolioProject.dbo.NashvilleHousing

--First update for address, appending OwnerSplitAddress to the NashvilleHousing table
ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

--Second update for city, appending OwnerSplitCity to the NashvilleHousing table
ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)


--Third update for state, appending OwnerSplitState to the NashvilleHousing table
ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


--Verify results
Select *
From PortfolioProject.dbo.NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

--We can see that SoldAsVacant is predominantly comprised of "Yes / No" with a few "Y / N"
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
order by 2


Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'	--changes the Y to Yes
	   When SoldAsVacant = 'N' THEN 'No'	--changes the N to No
	   ELSE SoldAsVacant					--otherwise keeps Yes/No
	   END
From PortfolioProject.dbo.NashvilleHousing

--Updating the original table with the casestatement:
Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END




-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

--Using ROW_NUMBER() to identify duplicate rows, partitioning to find entries with identical properties
--CTE was used to filter row_num > 1
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing
--order by ParcelID
)
--Replace select * with delete and comment out order by to delete the duplicate entries 
Select * 
From RowNumCTE
Where row_num > 1
Order by PropertyAddress


--Verifying
Select *
From PortfolioProject.dbo.NashvilleHousing




---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns (from view NOT from raw data)


Select *
From PortfolioProject.dbo.NashvilleHousing


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

