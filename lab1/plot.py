import json
import matplotlib.pyplot as plt
import os

# Create output directory if it doesn't exist
output_dir = "plots"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Read the JSON file
with open("results.json", "r") as file:
    data = json.load(file)

# Create a single figure for all plots
plt.figure(figsize=(12, 8))

# Iterate through each item in the JSON data and add to the same plot
for item in data:
    name = item["name"] if item["name"] else "unnamed"
    x_values = item["data"]["x"]
    y_values = item["data"]["y"]
    
    # Add this data series to the plot with a label
    plt.plot(x_values, y_values, marker='o', label=name)

# Add title and labels
plt.title("Combined Plot of All Items")
plt.xlabel("X values")
plt.ylabel("Y values")
plt.grid(True)

# Add a legend to distinguish between different data series
plt.legend()

# Save the combined plot
filename = os.path.join(output_dir, "combined_plot.png")
plt.savefig(filename)
plt.tight_layout()  # Adjust layout for better appearance

print(f"Combined plot saved as '{filename}'")
