import SiteKit

// Type-check against the built SiteKit module. Each INVALID_* flag selects a call that must fail; without a flag, every typed and explicit raw call must compile.
#if INVALID_GRID_COUNT
let invalidGrid = Style().grid(columns: 2.5)
#elseif INVALID_COLUMN_COUNT
let invalidColumns = Style().gridColumns(2.5)
#else
let grids = [
	Style().grid(columns: 2),
	Style().grid(columns: .fixed(.rootEm(12)), .flexible()),
	Style().grid(rawColumns: "subgrid"),
	Style().gridColumns(2),
	Style().gridColumns(.fixed(.rootEm(12)), .flexible()),
	Style().gridColumns(raw: "subgrid"),
]
#endif
