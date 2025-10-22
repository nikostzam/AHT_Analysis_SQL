# 🎯 KPI Performance and Outlier Management in a Call Center Environment  
### Using Dynamic Performance Targets & Six Sigma Lean Principles

---

## 📘 Overview

This SQL project automates **AHT (Average Handling Time)** performance tracking and **dynamic target generation** using **statistical modeling, percentile-based goals, and Six Sigma concepts**.

The process ensures that call center performance targets are fair, data-driven, and adaptable to each agent’s or skill’s performance profile.

---

## ⚙️ Step 1: Assigning a Baseline Performance Target

The first step involves setting a **performance target** for each employee, skill, or business line using a **50% inlier (median)** approach.  
This provides a balanced target that isn’t skewed by extreme high or low performers.

### 🧮 Logic:
- Calculate **AHT performance over the past 6 months**.
- Group data by **Employee** and **SkillID**.
- Filter only employees with **tenure ≥ 90 days**.
- Use `PERCENTILE_CONT(0.5)` to find the **median AHT** for each skill.

This median represents the **“optimal achievable”** AHT target for each skill group.

---

## ⚡ Step 2: Creating Dynamic AHT Goals

A static AHT target doesn’t reflect operational complexity — different skills require different handling times.  
To solve this, the code calculates a **Dynamic AHT Goal** for each employee and skill.

### 📈 KPI Defined:
**AHT Attainment = AHT Goal / Actual AHT**

This measures how close each agent’s performance is to the expected benchmark.

### 🧩 Key Fields Used:
| Field | Description |
|--------|-------------|
| `Date` | Date of performance record |
| `Employee` | Unique agent identifier |
| `SkillID` | Identifier for skill, language, or support group |
| `Calls` | Total interactions handled |
| `TotalHandlingTime` | Total time spent handling all calls |
| `AHT` | Average handling time (TotalHandlingTime / Calls) |
| `AHTGOAL` | Target AHT based on skill-level median |

---

## 📊 Step 3: Calculating Weekly & Monthly Attainment

Using **SQL Window Functions**, the script computes:

- `AHT Attainment_WeeklyPerSkill` → aggregated at skill-week level  
- `AHTATT` → weekly per employee  
- `AHT_Attainment_Month` → monthly per employee

This ensures the KPI is comparable both across time and teams.

---

## 🧹 Step 4: Outlier Detection using IQR

To improve accuracy, statistical **outliers** are removed using the **Interquartile Range (IQR)** method.

```sql
(Q3 - Q1) AS IQR,
(Q3 + 1.5 * IQR) AS UpperBound,
(Q1 - 1.5 * IQR) AS LowerBound

---

## 🧠 Step 5: Statistical Control & Six Sigma Logic

For the filtered data, monthly mean and standard deviation are calculated:

AVG(AHTATT) AS MeanATT,
STDEV(AHTATT) AS StdDevATT

---

## 🧩 Step 6: Dynamic Target Recalibration

Once statistical ranges are defined, the script dynamically recalculates new AHT targets for each agent, based on how far they are from the average performance.

🚀 Key Logic:

If AHT_Attainment_Month > 0.95 → No new target (already performing well)

If below LSS → Big improvement needed → target adjusted more aggressively

If between LSS and Mean → Moderate target reduction

If between Mean and 0.95 → Small incremental target reduction

CASE 
    WHEN AHT_Attainment_Month <= LSS THEN ...
    WHEN AHT_Attainment_Month BETWEEN LSS AND MeanATT THEN ...
    WHEN AHT_Attainment_Month BETWEEN MeanATT AND 0.95 THEN ...
END


🏆 Step 7: Final Output

The final result provides a ranked performance view per month:
This dataset enables supervisors and analysts to track continuous improvement across skills and individuals.

🧰 Technologies Used

Microsoft SQL Server (T-SQL)
BULK INSERT for CSV ingestion
Window Functions (SUM() OVER, AVG() OVER, STDEV() OVER)
PERCENTILE_CONT() for median calculation
IQR filtering for outlier removal
Six Sigma-based dynamic control limits
