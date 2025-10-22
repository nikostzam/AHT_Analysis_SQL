# AHT_Analysis_SQL
This project calculates **dynamic Average Handling Time (AHT) goals** and agent performance metrics using advanced SQL techniques such as window functions, percentile calculations, and statistical filtering.

🧠 Project Overview

The goal is to:
- Create a data model (`Fact_AHT`) that stores call handling data.
- Dynamically calculate **AHT attainment** based on goals.
- Detect and remove statistical outliers using **IQR (Interquartile Range)**.
- Compute performance statistics per month (Mean, Std Dev, Limits).
- Suggest **new dynamic AHT targets** for agents based on their performance level.



