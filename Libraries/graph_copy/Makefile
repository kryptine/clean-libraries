
all: copy_graph_to_string.o copy_graph_to_string_interface.o copy_string_to_graph.o copy_string_to_graph_interface.o

copy_graph_to_string.o: copy_graph_to_string.c copy_graph_to_string_implementation.c remove_forwarding_pointers_from_graph_implementation.c
	gcc -O -S -fomit-frame-pointer copy_graph_to_string.c -o copy_graph_to_string.a
	sed -f s.sed copy_graph_to_string.a > copy_graph_to_string.s
	as copy_graph_to_string.s -o copy_graph_to_string.o
	cp copy_graph_to_string.o "Clean System Files"/copy_graph_to_string.o

copy_graph_to_string_interface.o: copy_graph_to_string_interface.s
	as copy_graph_to_string_interface.s -o copy_graph_to_string_interface.o
	cp copy_graph_to_string_interface.o "Clean System Files"/copy_graph_to_string_interface.o

copy_string_to_graph.o: copy_string_to_graph.c copy_string_to_graph_implementation.c
	gcc -O -S -fomit-frame-pointer copy_string_to_graph.c -o copy_string_to_graph.a
	sed -f s.sed copy_string_to_graph.a > copy_string_to_graph.s
	as copy_string_to_graph.s -o copy_string_to_graph.o
	cp copy_string_to_graph.o "Clean System Files"/copy_string_to_graph.o

copy_string_to_graph_interface.o: copy_string_to_graph_interface.s
	as copy_string_to_graph_interface.s -o copy_string_to_graph_interface.o
	cp copy_string_to_graph_interface.o "Clean System Files"/copy_string_to_graph_interface.o
