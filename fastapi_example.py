from fastapi import FastAPI

app = FastAPI()


@app.get("/posts/{id}")
def read_item(id: str):
    return {"id": id}
