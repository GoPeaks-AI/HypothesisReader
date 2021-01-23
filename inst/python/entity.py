'''
The following script contains the functions related to predicting entity
classes
'''

# PACKAGES --------------------------------------------------------------------

import tensorflow as tf

# FUNCTIONS -------------------------------------------------------------------
'''
Prediction entity class

Input:
- hypothesis: numpy array of hypothesis
'''
# @tf.function(experimental_relax_shapes=True)
model_entity = tf.keras.models.load_model("./inst/extdata/models/entity_extraction/")

def entity_predict(hypothesis):
  print(hypothesis)
  
  hypothesis_tf = tf.convert_to_tensor(hypothesis)
  
  print(hypothesis_tf)

  pred_classes = model_entity.predict(hypothesis_tf)
  
  return(pred_classes)
