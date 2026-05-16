## Smart Local Train Guidance System – Tamil Nadu

This Flutter app tells the user **when to leave home** and **which local train to catch** so they can safely reach their **main station** (Egmore, Central, etc.) before the main train departure time.

### How it works

1. User enters:
   - Main station (e.g., `Chennai Egmore`)
   - Main train departure time (HH:mm, 24-hr)
   - Nearest local station (e.g., `Guindy`)
   - Approximate travel time from home to that station (in minutes)
2. App loads local/passenger train timetable from a JSON file in `assets/data/tn_local_trains.json`.
3. Core logic checks:
   - Home → local station travel time
   - Waiting time at station
   - Local train travel time (with a small delay simulation)
   - Buffer time before the main train departure
4. App recommends:
   - **When to leave home**
   - **Which local train to catch**
   - **Expected arrival time at the main station**

### Dataset

- Place your **Tamil Nadu local/passenger train timetable JSON** at:
  - `assets/data/tn_local_trains.json`
- Each record should follow:

```json
{
  "train_no": "43001",
  "train_name": "Chennai Beach – Tambaram Local",
  "from_station": "Chennai Beach",
  "to_station": "Tambaram",
  "departure_time": "10:10",
  "arrival_time": "11:05",
  "train_type": "Local",
  "districts_covered": ["Chennai", "Kancheepuram"]
}
```

### Legal disclaimer

> Train timings are based on official Indian Railways timetables. Actual timings may vary.

### Viva one-line explanation

> “This app tells users when to leave home and which local train to catch so they can reach their main station on time.”

