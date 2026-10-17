import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location('capture', Path(__file__).parent / 'board_capture/capture.py')
c = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(c)


class CaptureTest(unittest.TestCase):
    def test_recorder_never_adds_identifiers_and_uses_relative_time(self):
        now = [1000.0]
        stream = io.StringIO()
        r = c.Recorder(stream, c.header(), clock=lambda: now[0])
        now[0] += .5
        r.frame('rx', 'data', b'\x01\x24')
        records = [json.loads(s) for s in stream.getvalue().splitlines()]
        self.assertEqual(records[0], {'schema':c.SCHEMA,'board':'chessnut','model':'unspecified'})
        self.assertEqual(records[1], {'t_ms':500,'direction':'rx','characteristic':'data','hex':'0124'})
        r.closed = True
        self.assertFalse(r.frame('rx','data',b'\x00'))
        self.assertEqual(r.count, 1)

    def test_recording_limits_stop_without_partial_records(self):
        for count, elapsed, data in [(c.MAX_FRAMES, 0, b''), (0,601,b''), (0,0,b'\0'*513)]:
            stream=io.StringIO();now=[0]
            r=c.Recorder(stream,c.header(),clock=lambda:now[0])
            r.count=count;now[0]=elapsed
            self.assertFalse(r.frame('rx','data',data))
            self.assertTrue(r.closed)
            self.assertEqual(len(stream.getvalue().splitlines()),1)

    def test_unknown_metadata_and_identifiers_are_rejected(self):
        for field in ['name','address','mac','path','android_id','account']:
            with self.assertRaises(ValueError): c.validate_header({**c.header(),field:'PRIVATE'})
            with self.assertRaises(ValueError): c.validate_frame({'t_ms':0,'direction':'rx','characteristic':'data','hex':'',field:'PRIVATE'})
        for version in ['AA:BB:CC:DD:EE:FF','/Users/name/file','serial123', 'x'*1000]:
            with self.assertRaises(ValueError): c.header(firmware=version)
        self.assertEqual(c.header('go','1.2.3')['firmware'],'1.2.3')

    def test_frames_are_strict_and_bounded(self):
        frame={'t_ms':0,'direction':'rx','characteristic':'data','hex':'0e00'}
        for patch in [{'t_ms':-1},{'t_ms':True},{'t_ms':600001},{'hex':'gg'},
                      {'hex':'00 '*10},{'hex':'00'*513},{'direction':'tx'},
                      {'characteristic':'unrelated-uuid'}]:
            with self.assertRaises(ValueError): c.validate_frame({**frame,**patch})
        with self.assertRaises(ValueError): c.validate_frame(frame,1)

    def test_loader_and_default_output_privacy(self):
        self.assertEqual(c.DEFAULT_DIR.name,'captures')
        fixture=Path(__file__).resolve().parents[1]/'test/fixtures/board_protocol/decode-recovery.jsonl'
        self.assertEqual(c.load_capture(fixture),c.load_capture(fixture))
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'capture.jsonl'
            with c.exclusive_file(p) as f: f.write(json.dumps(c.header())+'\n')
            self.assertEqual(p.stat().st_mode & 0o777,0o600)
            with self.assertRaises(FileExistsError): c.exclusive_file(p)
            p.write_bytes(b'x'*(c.MAX_BYTES+1))
            with self.assertRaises(ValueError): c.load_capture(p)


class CaptureLifecycleTest(unittest.IsolatedAsyncioTestCase):
    async def test_capture_subscribes_only_to_board_and_stops_on_disconnect(self):
        from types import SimpleNamespace
        from unittest.mock import patch
        callbacks = {}; writes = []; exits = []
        class Scanner:
            @staticmethod
            async def discover(**kwargs):
                return {'PRIVATE-MAC': (object(), SimpleNamespace(local_name='Chessnut PRIVATE')),
                        'OTHER-MAC': (object(), SimpleNamespace(local_name='Unrelated device'))}
        class Client:
            def __init__(self, device, disconnected_callback, **kwargs):
                self.disconnected = disconnected_callback
                self.services = [SimpleNamespace(characteristics=[SimpleNamespace(uuid=u) for u in c.UUIDS.values()])]
            async def __aenter__(self): return self
            async def __aexit__(self,*args): exits.append(True)
            async def start_notify(self,uuid,callback): callbacks[uuid]=callback
            async def write_gatt_char(self,uuid,data,response):
                writes.append((uuid,data,response))
                if len(writes)==2:
                    callbacks[c.UUIDS['data']](None,b'\x01\x24'+bytes(32))
                    self.disconnected(None)
        module=SimpleNamespace(BleakClient=Client,BleakScanner=Scanner)
        with tempfile.TemporaryDirectory() as tmp, patch.dict('sys.modules',{'bleak':module}), \
             patch.object(c,'DEFAULT_DIR',Path(tmp)/'captures'), patch('sys.stdout',new_callable=io.StringIO) as out:
            path=await c.capture(SimpleNamespace(board_index=None,seconds=1,model='go',firmware=None))
            records=c.load_capture(path)
            raw=path.read_text()+out.getvalue()
            self.assertNotIn('PRIVATE',raw)
            self.assertNotIn('OTHER-MAC',raw)
            self.assertEqual(set(callbacks),{c.UUIDS['data'],c.UUIDS['confirm']})
            self.assertEqual([x[1].hex() for x in writes],['210100','290100'])
            self.assertEqual(len(records),4)
            self.assertEqual(exits,[True])
            size=path.stat().st_size
            callbacks[c.UUIDS['data']](None,b'late')
            self.assertEqual(path.stat().st_size,size)

    async def test_wrong_gatt_profile_is_rejected_before_writing(self):
        from types import SimpleNamespace
        from unittest.mock import patch
        writes=[]; exits=[]
        class Scanner:
            @staticmethod
            async def discover(**kwargs):
                return {'id':(object(),SimpleNamespace(local_name='Chessnut'))}
        class Client:
            def __init__(self,*args,**kwargs): self.services=[]
            async def __aenter__(self): return self
            async def __aexit__(self,*args): exits.append(True)
            async def write_gatt_char(self,*args,**kwargs): writes.append(args)
        with tempfile.TemporaryDirectory() as tmp, patch.dict('sys.modules',{'bleak':SimpleNamespace(BleakClient=Client,BleakScanner=Scanner)}), \
             patch.object(c,'DEFAULT_DIR',Path(tmp)/'captures'),patch('sys.stdout',new_callable=io.StringIO):
            with self.assertRaises(c.CaptureError):
                await c.capture(SimpleNamespace(board_index=None,seconds=1,model='unspecified',firmware=None))
            self.assertEqual(writes,[])
            self.assertEqual(exits,[True])
            self.assertEqual(list((Path(tmp)/'captures').iterdir()),[])


if __name__ == '__main__': unittest.main()
