
#include "uWS.h"
#include <iostream>

uWS::Hub h;
uWS::WebSocket<uWS::SERVER> *g_ws = nullptr;
void (*g_on_data)(char *message, size_t length) = nullptr;

void ws_write(char *message, size_t length) {
	if (g_ws) {
		g_ws->send(message, length, uWS::OpCode::TEXT);
	}
}

void ws_start(int port, void (*on_data)(char *message, size_t length)) {
	g_on_data = on_data;

	h.onConnection([](uWS::WebSocket<uWS::SERVER> *ws, uWS::HttpRequest req) {
		g_ws = ws;
		std::cout << "Connected ..." << std::endl;
	});

	h.onDisconnection([](uWS::WebSocket<uWS::SERVER> *ws, int code, char *message, size_t length) {
		g_ws = nullptr;
		std::cout << "Disconnected ..." << std::endl;
	});

	h.onMessage([](uWS::WebSocket<uWS::SERVER> *ws, char *message, size_t length, uWS::OpCode opCode) {
		g_on_data(message, length);
		ws->send(message, length, opCode);
	});

	h.listen(port);
	h.run();
}
