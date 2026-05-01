#!/bin/bash
# 检查所有已配置模型的连通性和选中状态
# 每个模型连续测试3次，间隔3秒
# 输出: 序号. 状态 模型名 (延迟) [当前]

CONFIG="${HOME}/.openclaw/openclaw.json"

if [ ! -f "$CONFIG" ]; then
    echo "错误: 配置文件不存在 $CONFIG"
    exit 1
fi

python3 << 'PYTHON_SCRIPT'
import json, subprocess, time, sys, os

config_path = os.environ.get('OPENCLAW_CONFIG') or os.path.join(os.path.expanduser('~'), '.openclaw', 'openclaw.json')

if len(sys.argv) > 1:
    config_path = sys.argv[1]

with open(config_path) as f:
    cfg = json.load(f)

models_cfg = cfg.get('agents',{}).get('defaults',{}).get('models',{})
providers = cfg.get('models',{}).get('providers',{})

primary = cfg.get('agents',{}).get('defaults',{}).get('model',{}).get('primary','')
fallbacks = cfg.get('agents',{}).get('defaults',{}).get('model',{}).get('fallbacks',[])

models_list = list(models_cfg.keys())

print("模型连通性检测 (3次测试，间隔3秒)")
print("=" * 60)

for i, model_key in enumerate(models_list, 1):
    parts = model_key.split('/', 1)
    if len(parts) == 2:
        provider_id, model_id = parts
    else:
        provider_id = model_key
        model_id = model_key
    
    provider = providers.get(provider_id, {})
    base_url = provider.get('baseUrl', '')
    api_key = provider.get('apiKey', '')
    
    if not base_url:
        print(f'{i:3d}. ⚠️  {model_key} (no base_url)')
        continue
    
    # 连续测试3次，间隔3秒
    successes = 0
    failures = 0
    latencies = []
    error_codes = []
    
    for attempt in range(3):
        if attempt > 0:
            time.sleep(3)
        
        try:
            start = time.time()
            payload = json.dumps({
                'model': model_id,
                'max_tokens': 16,
                'messages': [{'role': 'user', 'content': 'ping'}],
                'temperature': 0
            })
            
            result = subprocess.run([
                'curl', '-s', '-o', '/dev/null', '-w', '%{http_code}',
                '-m', '10',
                '-H', f'Authorization: Bearer {api_key}',
                '-H', 'Content-Type: application/json',
                '-d', payload,
                f'{base_url}/chat/completions'
            ], capture_output=True, text=True, timeout=12)
            
            elapsed = int((time.time() - start) * 1000)
            latencies.append(elapsed)
            
            if result.stdout == '200':
                successes += 1
            else:
                failures += 1
                error_codes.append(result.stdout)
                
        except subprocess.TimeoutExpired:
            failures += 1
            error_codes.append('timeout')
        except Exception as e:
            failures += 1
            error_codes.append(str(e))
    
    # 汇总结果
    marker = '[当前]' if model_key == primary else ('[备用]' if model_key in fallbacks else '')
    avg_latency = int(sum(latencies) / len(latencies)) if latencies else 0
    
    if successes == 3:
        status = '✅'
        detail = f'{avg_latency}ms'
    elif successes == 2:
        status = '⚠️'
        detail = f'{avg_latency}ms (2/3)'
    elif successes == 1:
        status = '❌'
        detail = f'{avg_latency}ms (1/3)'
    else:
        status = '❌'
        error_detail = ' '.join(error_codes[:3])
        detail = error_detail
    
    print(f'{i:3d}. {status} {model_key} ({detail}) {marker}')

PYTHON_SCRIPT
