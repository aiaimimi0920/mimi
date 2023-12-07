extends RefCounted


class_name WebSocketClient


@export var handshake_headers : PackedStringArray
@export var supported_protocols : PackedStringArray
@export var tls_trusted_certificate : X509Certificate
@export var tls_verify := true


var socket = WebSocketPeer.new()
var last_state = WebSocketPeer.STATE_CLOSED


signal connected_to_server()
signal connection_closed()
signal message_received(message)


func connect_to_url(url) -> int:
	close()
	clear()
	socket.inbound_buffer_size = 10485760
	socket.outbound_buffer_size = 10485760
	socket.supported_protocols = supported_protocols
	socket.handshake_headers = handshake_headers
	var err = socket.connect_to_url(url, TLSOptions.client(tls_trusted_certificate) if tls_verify else TLSOptions.client_unsafe(tls_trusted_certificate))
	if err != OK:
		return err
	return OK


func send(message) -> int:
	if typeof(message) == TYPE_STRING:
		return socket.send_text(message)
	elif message is PackedByteArray:
		return socket.send(message)
	return socket.send(var_to_bytes(message))


func get_message():
	if socket.get_available_packet_count() < 1:
		return null
	var pkt = socket.get_packet()
	if socket.was_string_packet():
		return pkt.get_string_from_utf8()
	return pkt


func close(code := 1000, reason := "") -> void:
	socket.close(code, reason)


func clear() -> void:
	socket = WebSocketPeer.new()


func get_socket() -> WebSocketPeer:
	return socket


func poll() -> void:
	if socket.get_ready_state() != socket.STATE_CLOSED:
		socket.poll()
	var state = socket.get_ready_state()
	if last_state != state:
		last_state = state
		if state == socket.STATE_OPEN:
			connected_to_server.emit()
		elif state == socket.STATE_CLOSED:
			connection_closed.emit()
	while socket.get_ready_state() == socket.STATE_OPEN and socket.get_available_packet_count():
		message_received.emit(get_message())
