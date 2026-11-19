package main

type DataA struct {
	ID    int     `json:"id"`
	Name  string  `json:"name"`
	Value int     `json:"value"`
	DataB []DataB `json:"dataBList,omitempty"`
}

type DataB struct {
	ID          int    `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description"`
}
