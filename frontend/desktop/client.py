"""HTTP client for the desktop. No SQL driver or database credentials here."""
import os
from uuid import uuid4
import httpx

class ApiError(RuntimeError):
    def __init__(self,message,status_code):
        super().__init__(message)
        self.status_code=status_code


class Api:
    def __init__(self):
        self.url=os.environ.get("PPE_API_URL","http://127.0.0.1:8765")
        self.token=os.environ.get("PPE_DEMO_TOKEN","")

    def request(self,method,path,**kwargs):
        with httpx.Client(timeout=40,trust_env=False) as client:
            response=client.request(method,self.url+path,headers={"Authorization":"Bearer "+self.token},**kwargs)
        if response.is_error:
            try: message=response.json().get("detail","La operación no se pudo completar.")
            except ValueError: message="Respuesta inesperada del servicio."
            raise ApiError(str(message),response.status_code)
        return response.json()

    def snapshot(self): return self.request("GET","/demo/snapshot")
    def sample(self): return self.request("GET","/demo/sample")
    def command(self,action,**payload):
        return self.request("POST","/demo/commands/"+action,json={"key":str(uuid4()),"payload":payload})
