package enet;

// docs: http://leafo.net/lua-enet/
extern class ENetHost {
	function connect(address: String, ?channel_count: Int, ?data: Int): ENetPeer {}
	function service(?timeout: Int): Null<Event> {}
	function check_events(): Null<Event> {}
	function compress_with_range_coder(): Void {}
	function flush(): Void {}
	function broadcast(data: Int, ?channel: Int, ?flag: PacketSequenceMode): Void {}
	function channel_limit(limit: Int): Void {}
	function bandwidth_limit(incoming: Int, outgoing: Int): Void {}
	function total_sent_data(): Int {}
	function total_received_data(): Int {}
	function service_time(): Int {}
	function peer_count(): Int {}
	function get_peer(index: Int): ENetPeer {}
	function get_socket_address(): String {}
}

extern class ENetPeer {
	function connect_id(): Int {}
	function disconnect(?data: Int): Void {}
	function disconnect_now(?data: Int): Void {}
	function disconnect_later(?data: Int): Void {}
	function index(): Int {}
	function ping(): Void {}
	function ping_interval(interval: Int): Void {}
	function reset(): Void {}
	function send(data: String, ?channel: Int, ?flag: PacketSequenceMode): Void {}
	function state(): PeerState {}
	function receive(): Void {}
	function round_trip_time(?value: Int): Int {}
	function last_round_trip_time(?value: Int): Int {}
	function throttle_configure(interval: Int, acceleration: Float, deceleration: Float): Void {}
	function timeout(limit: Float, minimum: Int, maximum: Int): Void {}
}

@:luaRequire("enet")
extern class ENet {
	static function host_create(?bind_address: String, ?peer_count: Int, ?channel_count: Int, ?in_bandwidth: Int, ?out_bandwidth: Int): ENetHost {}

	static inline function simple_server(host: String, port: Int, timeout: Int = 100, run: Event->Bool, ?poll: Void->Bool): Void {
		var server = ENet.host_create('$host:$port');
		var running = true;
		while (running) {
			var event = server.service(timeout);
			if (poll != null) {
				running = !poll();
			}
			if (event == null) {
				continue;
			}
			var kill = run(event);
			if (kill) {
				running = false;
			}
		}
		server.flush();
	}

	static inline function simple_client(host: String, port: Int, timeout: Int = 100, run: Event->Bool, poll: Void->Bool): Void {
		var server = ENet.host_create();
		server.connect('$host:$port');

		var peer: ENetPeer = null;
		var running = true;
		while (running) {
			var event = server.service(timeout);
			if (poll != null) {
				running = !poll();
			}
			if (event == null) {
				continue;
			}
			switch (event.type) {
				case Connect: peer = event.peer;
				case Disconnect: peer = null;
				default: // pass
			}
			var kill = run(event);
			if (kill) {
				running = false;
			}
		}

		if (peer != null) {
			peer.disconnect();
		}
	}
}
