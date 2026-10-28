package main
import("crypto/sha256";"encoding/hex";"encoding/json";"errors";"io";"net/http";"net/url";"os";"path/filepath";"fmt";"time")
const maxAPK = 300_000_000
var errAPKTooBig=errors.New("apk exceeds the size limit")
var errAPKHash=errors.New("the downloaded apk does not match its hash")
func keepAPK(r io.Reader, dir, blob string) (io.ReadSeeker, func(), error) {
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return nil, nil, err
	}
	f, err := os.CreateTemp(dir, ".relay-apk-*")
	if err != nil {
		return nil, nil, err
	}
	fail := func(err error) (io.ReadSeeker, func(), error) {
		f.Close()
		os.Remove(f.Name())
		return nil, nil, err
	}
	hasher := sha256.New()
	n, err := io.Copy(io.MultiWriter(f, hasher), io.LimitReader(r, maxAPK+1))
	if err != nil {
		return fail(err)
	}
	if n > maxAPK {
		return fail(errAPKTooBig)
	}
	if hex.EncodeToString(hasher.Sum(nil)) != blob {
		return fail(errAPKHash)
	}
	if err := os.Rename(f.Name(), filepath.Join(dir, blob+".apk")); err != nil {
		return fail(err)
	}
	if _, err := f.Seek(0, io.SeekStart); err != nil {
		f.Close()
		return nil, nil, err
	}
	return f, func() { f.Close() }, nil
}


type counted struct{r io.Reader;n int64}
func(c *counted)Read(p []byte)(int,error){n,e:=c.r.Read(p);c.n+=int64(n);return n,e}
func main(){start:=time.Now();dir:=os.Args[1];if e:=os.Mkdir(dir,0700);e!=nil{panic(e)};defer os.Remove(dir);client:=http.Client{Timeout:180*time.Second};res,e:=client.Get("https://github.com/Dash1971/maia-chess-android/releases/download/v2.5.1/Mobile-Maia-v2.5.1.apk");if e!=nil{panic(e)};defer res.Body.Close();if res.StatusCode!=200{panic(res.Status)};r:=&counted{r:res.Body};_,_,e=keepAPK(r,dir,"59f730e806b6ead163714c46bf93f163309f8e6fb50295fe943112367be25f80");files,err:=os.ReadDir(dir);if err!=nil{panic(err)};if !errors.Is(e,errAPKTooBig)||r.n!=300000001||len(files)!=0{panic("unexpected reproduction result")};u,_:=url.Parse(res.Request.URL.String());report:=map[string]any{"checked_at":time.Now().UTC().Format(time.RFC3339),"source_commit":"0f1ae2eabb9ed4b94bb2f42ed26799c7c0d42180","scope":"isolated unmodified keepAPK function and maxAPK constant copied from pinned public relay source; not a reproduction on the production server","http_status":res.StatusCode,"download_host":u.Host,"expected_apk_bytes":455440608,"declared_content_length":res.ContentLength,"bytes_read_before_rejection":r.n,"reader_limit_bytes":maxAPK,"error":e.Error(),"partial_file_removed":true,"seconds":time.Since(start).Seconds()};b,_:=json.MarshalIndent(report,"","  ");fmt.Println(string(b))}
