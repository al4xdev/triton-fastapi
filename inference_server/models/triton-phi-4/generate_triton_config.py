import onnx
import os

def generate_triton_io_sections(model_path):
    model = onnx.load(model_path)
    graph = model.graph

    triton_data_type_map = {
        "TENSORPROTO.FLOAT": "TYPE_FP32",
        "TENSORPROTO.FLOAT16": "TYPE_FP16",
        "TENSORPROTO.INT8": "TYPE_INT8",
        "TENSORPROTO.INT16": "TYPE_INT16",
        "TENSORPROTO.INT32": "TYPE_INT32",
        "TENSORPROTO.INT64": "TYPE_INT64",
        "TENSORPROTO.BOOL": "TYPE_BOOL",
        "TENSORPROTO.DOUBLE": "TYPE_FP64",
        "TENSORPROTO.UINT8": "TYPE_UINT8",
        "TENSORPROTO.UINT16": "TYPE_UINT16",
        "TENSORPROTO.UINT32": "TYPE_UINT32",
        "TENSORPROTO.UINT64": "TYPE_UINT64",
        "TENSORPROTO.STRING": "TYPE_STRING",
        "TENSORPROTO.BFLOAT16": "TYPE_BF16",
    }

    input_lines = []
    for input_proto in graph.input:
        name = input_proto.name
        elem_type = onnx.helper.tensor_dtype_to_string(input_proto.type.tensor_type.elem_type)
        
        triton_data_type = triton_data_type_map.get(elem_type.upper(), "UNKNOWN_TYPE")

        raw_dims = [d.dim_value if d.dim_value != 0 else -1 for d in input_proto.type.tensor_type.shape.dim]
        
        # Se max_batch_size > 0 no config.pbtxt, o Triton já adiciona a dimensão de batch.
        # Então, se a primeira dimensão do ONNX é -1 (batch), nós a removemos aqui.
        if len(raw_dims) > 0 and raw_dims[0] == -1:
            dims = raw_dims[1:] # Remove a primeira dimensão
        else:
            dims = raw_dims # Mantém como está se não for batch dinâmico ou se for fixo

        dims_str = ", ".join(map(str, dims))

        input_lines.append(f"  {{\n    name: \"{name}\"\n    data_type: {triton_data_type}\n    dims: [ {dims_str} ]\n  }}")
    
    output_lines = []
    for output_proto in graph.output:
        name = output_proto.name
        elem_type = onnx.helper.tensor_dtype_to_string(output_proto.type.tensor_type.elem_type)
        
        triton_data_type = triton_data_type_map.get(elem_type.upper(), "UNKNOWN_TYPE")

        raw_dims = [d.dim_value if d.dim_value != 0 else -1 for d in output_proto.type.tensor_type.shape.dim]
        if len(raw_dims) > 0 and raw_dims[0] == -1:
            dims = raw_dims[1:] # Remove a primeira dimensão
        else:
            dims = raw_dims

        dims_str = ", ".join(map(str, dims))

        output_lines.append(f"  {{\n    name: \"{name}\"\n    data_type: {triton_data_type}\n    dims: [ {dims_str} ]\n  }}")

    input_section = "input [\n" + ",\n".join(input_lines) + "\n]"
    output_section = "output [\n" + ",\n".join(output_lines) + "\n]"

    return input_section, output_section

if __name__ == "__main__":
    model_version_dir = "1" 
    onnx_model_file = os.path.join(model_version_dir, "model.onnx")

    if not os.path.exists(onnx_model_file):
        print(f"Erro: Arquivo ONNX não encontrado em '{onnx_model_file}'")
        exit(1)

    input_section_content, output_section_content = generate_triton_io_sections(onnx_model_file)
    
    output_dir = os.path.dirname(os.path.abspath(os.path.join(onnx_model_file, os.pardir)))
    output_config_path = os.path.join(output_dir, "config.pbtxt")

    try:
        with open(output_config_path, "w") as f:
            f.write("name: \"Phi-4-reasoning-plus-onnx\"\n")
            f.write("platform: \"onnxruntime_onnx\"\n")
            f.write("max_batch_size: 40\n\n")
            f.write(input_section_content)
            f.write("\n\n")
            f.write(output_section_content)
            f.write("\n\n")
            f.write("instance_group [\n  {\n    count: 1\n    kind: KIND_GPU\n  }\n]\n")


        print(f"config.pbtxt gerado com sucesso em: {output_config_path}")
        print("Lembre-se de verificar os parâmetros do modelo (num_layers, num_heads, head_dim) para o KV Cache!")

    except Exception as e:
        print(f"Ocorreu um erro ao gerar o config.pbtxt: {e}")
