import json
import matplotlib.pyplot as plt
import os

# Load data from JSON file
with open('results.json', 'r') as f:
    data = json.load(f)

# Verify data structure
if len(data) != 4:
    raise ValueError("Expected 4 rows of data in the JSON file")

# Algorithm names corresponding to the rows
algorithms = [
    'Quick Sort',
    'Merge Sort',
    'Heap Sort',
    'Base 256 Radix Sort'
]

# Create plot
plt.figure(figsize=(12, 6))

# Plot each algorithm's data
for i in range(4):
    plt.plot(data[i], label=algorithms[i])

# Add labels and title
plt.xlabel('Test Case Index')
plt.ylabel('Execution Time (miliseconds)')
plt.title('Sorting Algorithm Performance Comparison')
plt.legend()
plt.grid(True)

# Save the time plot
plt.savefig("time_plot.png")

# Show the plot
plt.tight_layout()
plt.show()

