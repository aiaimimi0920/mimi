
# from multiprocessing import Lock
import threading

class SingletonType(type):
    def __new__(mcs, name, bases, attrs):
        cls = super(SingletonType, mcs).__new__(mcs, name, bases, attrs)
        cls.__shared_instance_lock__ = threading.Lock()
        return cls

    def __call__(cls, *args, **kwargs):
        with cls.__shared_instance_lock__:
            try:
                return cls.__shared_instance__
            except AttributeError:
                cls.__shared_instance__ = super(SingletonType, cls).__call__(*args, **kwargs)
                return cls.__shared_instance__
