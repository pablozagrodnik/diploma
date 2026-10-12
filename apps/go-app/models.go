package main

type DataA struct {
	ID    int     `json:"id"`
	Name  string  `json:"name"`
	Value int     `json:"value"`
	DataB []DataB `json:"dataB,omitempty"`
}

type DataB struct {
	ID          int    `json:"-"`
	Title       string `json:"title"`
	Description string `json:"description"`
}
