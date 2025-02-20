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

# Iterate through each item in the JSON data
for item in data:
    name = item["name"] if item["name"] else "unnamed"
    x_values = item["data"]["x"]
    y_values = item["data"]["y"]
    
    # Create a new figure for each plot
    plt.figure(figsize=(10, 6))
    
    # Create the plot
    plt.plot(x_values, y_values, marker='o')
    
    # Add title and labels
    plt.title(f"Plot for {name}")
    plt.xlabel("X values")
    plt.ylabel("Y values")
    plt.grid(True)
    
    # Generate a filename (replace spaces with underscores for safety)
    safe_name = name.replace(" ", "_") if name else "unnamed"
    filename = os.path.join(output_dir, f"{safe_name}.png")
    
    # Save the plot as PNG
    plt.savefig(filename)
    plt.close()
    
    print(f"Generated plot for '{name}' saved as '{filename}'")

print(f"All plots have been saved to the '{output_dir}' directory.")
