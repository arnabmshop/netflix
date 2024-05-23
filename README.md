# Netflix Data Analysis Project

This project focuses on analyzing Netflix data obtained from Kaggle using the Kaggle API. The dataset contains information about various shows available on Netflix.

## Data Source
The dataset is sourced from Kaggle and can be found at (https://www.kaggle.com/datasets/shivamb/netflix-shows).

## Data Processing
Upon downloading the dataset, it is received in a zip file format. Python is utilized to extract the CSV file from this zip file. The Pandas library is then employed to explore and manipulate the dataset.

## Loading Data to SQL Server
The dataset is loaded into an SQL Server database from Python. Several operations are performed on the SQL Server:

1. **Redefining Table Schema**: The table schema is adjusted as per the project requirements.
2. **Removing Duplicate Records**: Duplicate records are identified and removed to ensure data integrity.
3. **Normalization**: To reduce redundancy, the raw table is split into subtables. These subtables include directors, cast, country, listed_in (genre), and a main table called `netflix_main`. Relationships between these tables are established through the `show_id` column, acting as the primary key.
4. **Handling Null Values**: Efforts are made to remove null values where possible to enhance the quality of the data.

## Data Analysis
The dataset undergoes thorough analysis to derive insights and answer pertinent questions:

1. **Director Analysis**: Count the number of movies and TV shows created by each director, separately for directors involved in both movie and TV show production.
2. **Country Analysis**: Identify the country with the highest number of comedy movies.
3. **Yearly Director Analysis**: Determine, for each year based on the date added to Netflix, which director has the maximum number of movies released.
4. **Genre Duration Analysis**: Calculate the average duration of movies and TV shows in each genre.
5. **Director Genre Analysis**: Find the list of directors who have created both horror and comedy movies, along with the number of each.

## Usage
To replicate the analysis or explore the dataset further, follow these steps:
1. Download the dataset from the provided Kaggle link.
2. Extract the CSV file using Python.
3. Load the data into an SQL Server database.
4. Execute the provided SQL queries for analysis.

## Dependencies
- Python (3.x)
- Pandas
- SQL Server

## Contributors
- Arnab Chakraborty

## License
MIT
