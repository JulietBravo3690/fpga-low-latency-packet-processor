# Metadata Pipeline

The top-level packet processor separates the design into a data plane and a metadata plane.

## Data Plane

The data plane carries raw packet bytes through the design.

```text
data_in
valid_in
sop_in
eop_in