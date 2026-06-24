# Digital Vehicle Telemetry System in Verilog

A digital hardware design project implementing a real-time car telemetry system with cruise control, hill slope compensation, fuel estimation, and safety alerts. Built for CS203 coursework.

## Features

- **Velocity tracking** from position sensor input
- **Cruise control** (P-controller) to maintain target speed
- **Hill slope compensation** — adjusts acceleration for uphill/downhill terrain
- **Fuel estimation** — accumulates fuel proportional to velocity
- **Safety alerts** — overspeed (>100) and harsh brake (<-20) warnings
- **Distance counter** — total distance traveled

## System Architecture

```
position_in ──► position_reg ──► delta_calc ──► velocity_calc ──► delta_calc ──► accel_calc
                                     │              │                │                │
                                     │              │                │                ▼
                                     │              │                │         hill_slope_calc ◄── slope_angle
                                     │              │                │                │
                                     │              │                │         tom_cruise_calc ◄── target_speed
                                     │              │                │                │
                                     │              │                │         acceleration_final
                                     │              │                │                │
                                     │              │                │    ┌───────────┼───────────┐
                                     │              │                │    │           │           │
                                     │              │                ▼    ▼           ▼           ▼
                                     │              │         alert_unit  fuel_estimator  distance_counter
                                     │              │
                                     │              ▼
                                     │         velocity (output)
                                     │
                                     ▼
                              distance (output)
```

## Modules

| Module | Description |
|--------|-------------|
| `position_reg.v` | Registers current + previous position readings |
| `delta_calc.v` | Computes position and velocity differences |
| `velocity_calc.v` | Calculates velocity from position delta |
| `accel_calc.v` | Calculates acceleration from velocity delta |
| `hill_slope_calc.v` | Slope compensation (uphill reduces, downhill adds) |
| `tom_cruise_calc.v` | Cruise control P-controller (Kp=1) |
| `fuel_estimator.v` | Fuel accumulation over time |
| `distance_counter.v` | Total distance traveled |
| `alert_unit.v` | Overspeed and harsh brake safety flags |
| `telemetry_top.v` | Top-level module connecting all subsystems |
| `testbench.v` | Testbench with 6 driving scenarios |

## Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `TIME_STEP` | 10 | Divider for velocity/acceleration calculation |
| `CLK_PERIOD` | 10 ns | Clock period |
| `OVERSPEED_LIMIT` | 100 | Velocity threshold for overspeed alert |
| `BRAKE_LIMIT` | -20 | Acceleration threshold for harsh brake alert |
| `Kp` (cruise) | 1 | Proportional gain for cruise control |
| `SLOPE_FACTOR` | 1 | Slope angle multiplier |

## Driving Scenarios (Testbench)

| Scenario | Target Speed | Slope | Key Test |
|----------|-------------|-------|----------|
| 1. Acceleration | 50 | 0° | Velocity increases 10→80 |
| 2. Constant Speed | 50 | 0° | Cruise control balanced, accel→0 |
| 3. Overspeed | 40 | 0° | Velocity=120, alert_flags[1]=1 |
| 4. Harsh Braking | 0 | 0° | Accel=-45, alert_flags[0]=1 |
| 5. Settling | 20 | 0° | Stabilization after braking |
| 6. Uphill Slope | 50 | +10° | Accel reduced by ~10 |
| 7. Downhill Slope | 50 | -10° | Accel increased by ~10 |

## How to Run

### Requirements
- [Icarus Verilog](https://bleyer.org/icarus/) (iverilog + vvp)
- [GTKWave](https://gtkwave.sourceforge.net/) (optional, for waveform viewing)
- Python 3 + matplotlib + numpy (optional, for dashboard generation)

### Compile & Simulate
```bash
cd src
iverilog -o telemetry_sim.vvp *.v
vvp telemetry_sim.vvp
```

### View Waveforms (GTKWave)
```bash
gtkwave telemetry_top.vcd
```
> **Tip:** Right-click `acceleration_final`, `slope_angle`, `target_speed` → **Data Format → Signed Decimal** to see negative values correctly.

### Generate Dashboard (Optional)
```bash
pip install matplotlib numpy
python generate_dashboard.py
```

## Simulation Results

See `docs/sim_output.txt` for terminal output and `docs/telemetry_dashboard.html` for the visual dashboard.

## Key Formulas

| Module | Formula |
|--------|---------|
| velocity | `Δposition / TIME_STEP` |
| acceleration | `Δvelocity / TIME_STEP` |
| hill slope | `accel_out = accel_in − (slope × SLOPE_FACTOR)` |
| cruise control | `control = Kp × (target − velocity)` |
| fuel | `fuel += velocity + 1` |
| distance | `distance += |Δposition|` |
| alerts | `overspeed = vel > 100`, `harsh_brake = accel < −20` |

## Repository Structure

```
├── src/                          # Verilog source files
│   ├── telemetry_top.v
│   ├── testbench.v
│   ├── position_reg.v
│   ├── delta_calc.v
│   ├── velocity_calc.v
│   ├── accel_calc.v
│   ├── hill_slope_calc.v
│   ├── tom_cruise_calc.v
│   ├── fuel_estimator.v
│   ├── distance_counter.v
│   └── alert_unit.v
├── docs/
│   ├── telemetry_dashboard.html  # Visual dashboard
│   ├── telemetry_dashboard_embedded.html  # Self-contained dashboard (images embedded)
│   ├── sim_output.txt            # Terminal output
│   └── assets/                   # Dashboard plots
│       ├── plot_overview.png
│       ├── plot_velocity_position.png
│       ├── plot_acceleration_slope.png
│       ├── plot_fuel_distance.png
│       └── plot_alerts.png
├── README.md
└── .gitignore
```

## License

This is a CS203 coursework project.
