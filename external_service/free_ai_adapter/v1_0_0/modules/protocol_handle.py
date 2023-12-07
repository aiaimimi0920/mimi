import json
from . import main_protocol_pb2
from google.protobuf import json_format as json_format
from free_ai.singleton import SingletonType
import six
def set_default(obj):
    if isinstance(obj, set):
        return list(obj)
    raise TypeError


@six.add_metaclass(SingletonType)
class ProtocolHandle(object):
	protocol_map = {}
	c_s_protocol_map = {}
	s_c_protocol_map = {}

	data_format = "protobuf"
    
	def __init__(self, cur_data_format="protobuf"):
		self.data_format = cur_data_format
		self.protocol_map = {}
		self.c_s_protocol_map = {}
		self.s_c_protocol_map = {}

	def register_protocol_format_with_object(self, sub_protocol, object):
		self.register_c_s_protocol_format_with_object(sub_protocol, object)
		self.register_s_c_protocol_format_with_object(sub_protocol, object)

	def get_main_potocol_id(self, potocol_cls):
		main_protocol_name = 0
		for key in potocol_cls.keys():
			if potocol_cls.Value(key)!=0:
				main_protocol_name = key
				break
		return main_protocol_name

	def get_sub_protocol_map(self, potocol_cls):
		sub_protocol_map = {}
		for key in potocol_cls.keys():
			if potocol_cls.Value(key)!=0:
				sub_protocol_map[key] = potocol_cls.Value(key)
		return sub_protocol_map

	def register_c_s_protocol_format_with_object(self, sub_protocol, object):
		main_protocol_name = self.get_main_potocol_id(sub_protocol.C2SMAINPROTOCOL)
		sub_protocol_map = self.get_sub_protocol_map(sub_protocol.C2SPROTOCOL)
		for protocol_name in sub_protocol_map:
			self.register_c_s_protocol_format(main_protocol_name, sub_protocol_map[protocol_name], getattr(sub_protocol,"M_"+protocol_name), getattr(object, protocol_name))

	def register_s_c_protocol_format_with_object(self, sub_protocol, object):
		main_protocol_name = self.get_main_potocol_id(sub_protocol.S2CMAINPROTOCOL)
		sub_protocol_map = self.get_sub_protocol_map(sub_protocol.S2CPROTOCOL)
		for protocol_name in sub_protocol_map:
			self.register_s_c_protocol_format(main_protocol_name, sub_protocol_map[protocol_name], getattr(sub_protocol,"M_"+protocol_name), getattr(object, protocol_name))


	def register_c_s_protocol_format(self, protocol_name, sub_protocol, probuf_cls, callable=None):
		self.register_protocol_format(protocol_name,sub_protocol,probuf_cls, main_protocol_pb2.C2SPROTOCOL, self.c_s_protocol_map, callable)

	def register_s_c_protocol_format(self,protocol_name, sub_protocol, probuf_cls, callable=None):
		self.register_protocol_format(protocol_name,sub_protocol,probuf_cls, main_protocol_pb2.S2CPROTOCOL, self.s_c_protocol_map, callable)
			
	def register_protocol_format(self, protocol_name, sub_protocol, probuf_cls, main_protocol_cls, protocol_map, callable=None):
		protocol = protocol_name
		if isinstance(protocol_name,str):
			protocol = getattr(main_protocol_cls, protocol_name)
		if protocol not in protocol_map:
			protocol_map[protocol] = {}
		protocol_map[protocol][sub_protocol] = {"format":probuf_cls,"callable":callable}
		protocol_map[callable] = {"protocol":protocol, "sub_protocol": sub_protocol}

	def unregister_c_s_protocol_format(self,protocol_name, sub_protocol):
		self.unregister_protocol_format(protocol_name, sub_protocol, main_protocol_pb2.C2SPROTOCOL, self.c_s_protocol_map)

	def unregister_s_c_protocol_format(self, protocol_name, sub_protocol):
		self.unregister_protocol_format(protocol_name, sub_protocol, main_protocol_pb2.S2CPROTOCOL, self.s_c_protocol_map)


	def unregister_protocol_format(self, protocol_name, sub_protocol, main_protocol_cls, protocol_map):
		protocol = protocol_name
		if type(protocol_name) is str:
			protocol = getattr(main_protocol_cls, protocol_name)
		if protocol not in protocol_map:
			return 
		if sub_protocol in protocol_map[protocol] and "callable" in protocol_map[protocol][sub_protocol]:
			protocol_map.pop(protocol_map[protocol][sub_protocol]["callable"])
		protocol_map[protocol].pop(sub_protocol)


	def parse_content(self, protocol, sub_protocol, content):
		if protocol not in self.c_s_protocol_map:
			return content
		if sub_protocol not in self.c_s_protocol_map[protocol]:
			return content
		c2s = self.c_s_protocol_map[protocol][sub_protocol]["format"]()
		c2s.ParseFromString(content)

		content_map = json_format.MessageToDict(c2s,False,True)
		return content_map

	def parse_data(self, data):
		result_data = None
		if self.data_format.lower() == "json":
			result_data = json.loads(data)
		elif self.data_format.lower() == "protobuf":
			c2s = main_protocol_pb2.C2S()
			c2s.ParseFromString(data)
			content = self.parse_content(c2s.protocol, c2s.sub_protocol, c2s.content)
			result_data = {
				"protocol":c2s.protocol,
				"sub_protocol":c2s.sub_protocol,
				"syncId":c2s.syncId,
				"server_syncId":c2s.server_syncId,
				"content":content,
			}
		callable = None

		if (result_data["protocol"] in self.c_s_protocol_map) and (result_data["sub_protocol"] in self.c_s_protocol_map[result_data["protocol"]]):
			callable = self.c_s_protocol_map[result_data["protocol"]][result_data["sub_protocol"]].get("callable",None)
		
		
		return [result_data, callable]


	def stringify(self, server_syncId, syncId, content, caller):
		if caller not in self.s_c_protocol_map:
			return False
		protocol = self.s_c_protocol_map[caller]["protocol"]
		sub_protocol = self.s_c_protocol_map[caller]["sub_protocol"]
		dict_data = {
			"protocol":protocol,
			"sub_protocol":sub_protocol,
			"syncId":syncId,
			"server_syncId":server_syncId,
			"content":content,
		}
		result_data = None

		if self.data_format.lower() == "json":
			result_data = json.dumps(dict_data, default=set_default)
		elif self.data_format.lower() == "protobuf":
			s2c = main_protocol_pb2.S2C()
			s2c.protocol = protocol
			s2c.sub_protocol = sub_protocol
			s2c.syncId = syncId
			s2c.content = self.stringify_content(protocol, sub_protocol, content)
			result_data = s2c.SerializeToString()
		return [result_data,dict_data]


	def stringify_content(self, protocol, sub_protocol, content):
		if protocol not in self.s_c_protocol_map:
			return content
		if sub_protocol not in self.s_c_protocol_map[protocol]:
			return content
		s2c = self.s_c_protocol_map[protocol][sub_protocol]["format"]()
		s2c = json_format.ParseDict(content, s2c, True)
		return s2c.SerializeToString()
