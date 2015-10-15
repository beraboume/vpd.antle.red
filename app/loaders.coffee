# Dependencies
vpd= require 'vpvp-vpd'

# Publish
app= angular.module process.env.APP
app.factory 'Loaders',($window,Promise,renderer)->
  class Loader
    constructor: (pmxName,vmdName)->
      @clock= new THREE.Clock

      @pmx= @loadPmx pmxName
      @vmd= @loadVmd vmdName
      @model= @createModel()

    isFulfilled: ->
      @pmx.isFulfilled() and @vmd.isFulfilled()

    nextDelta: ->
      @delta= @clock.getDelta()

    loadPmx: (pmxName,params={})->
      new Promise (resolve)->
        pmx= new THREE.MMD.PMX
        pmx.load pmxName,(pmx)->
          pmx.createMesh params,(mesh)->
            resolve {pmx,mesh}

    loadVmd: (vmdName)->
      new Promise (resolve)->
        vmd= new THREE.MMD.VMD
        vmd.load vmdName,resolve

    loadVpd: (vpdName)->
      new Promise (resolve)->
        xhr= new XMLHttpRequest
        xhr.open 'GET',vpdName,yes
        xhr.responseType= 'arraybuffer'
        xhr.send()
        xhr.onload= ->
          resolve vpd.parse new Buffer xhr.response

    generateSkinAnimation: (pmx,vpd)->
      duration= 0.03333333333333333
      targets= []

      for pBone in pmx.bones
        keys= []

        for vBone in vpd.bones
          continue unless pBone.name is vBone.name

          pos= vBone.position.slice()
          rot= vBone.quaternion.slice()
          rot[0]*= -1
          rot[1]*= -1
          interp= new Uint8Array [20,20,0,0,20,20,20,20,107,107,107,107,107,107,107,107]

          keys.push
            name: vBone.name
            time: 0
            pos: pos
            rot: rot
            interp: interp

          keys.push
            name: vBone.name
            time: duration
            pos: pos
            rot: rot
            interp: interp

        targets.push {keys}

      {duration,targets}

    createModel: ->
      Promise.all [@pmx,@vmd]
      .spread ({pmx,mesh},vmd)=>
        mAnimation= vmd.generateMorphAnimation pmx
        morph= new THREE.MMD.MMDMorph mesh, mAnimation if mAnimation

        sAnimation= vmd.generateSkinAnimation pmx
        skin= new THREE.MMD.MMDSkin mesh, sAnimation if sAnimation

        if mesh.geometry.MMDIKs.length
          ik= new THREE.MMD.MMDIK mesh

        if mesh.geometry.MMDIKs.length and window.Ammo
          physi= new THREE.MMD.MMDPhysi mesh
          physiPlugin=
            render: =>
              physi.preSimulate @delta
              THREE.MMD.btWorld.stepSimulation @delta
              physi.postSimulate @delta

        hasAd= pmx.bones.some (bone)-> bone.additionalTransform
        addTrans= new THREE.MMD.MMDAddTrans pmx, mesh if hasAd

        {mesh,morph,skin,ik,physi,physiPlugin,addTrans}

  class VpdLoader extends Loader
    constructor: (pmxName,vpdName)->
      @clock= new THREE.Clock

      @pmx= @loadPmx pmxName
      @vpd= @loadVpd vpdName
      @model= @createModel()

    isFulfilled: ->
      @pmx.isFulfilled() and @vpd.isFulfilled()

    createModel: ->
      Promise.all [@pmx,@vpd]
      .spread ({pmx,mesh},vpd)=>
        morph= null

        sAnimation= @generateSkinAnimation pmx,vpd
        skin= new THREE.MMD.MMDSkin mesh, sAnimation if sAnimation

        if mesh.geometry.MMDIKs.length
          ik= new THREE.MMD.MMDIK mesh

        if mesh.geometry.MMDIKs.length and window.Ammo
          physi= new THREE.MMD.MMDPhysi mesh
          physiPlugin=
            render: =>
              physi.preSimulate @delta
              THREE.MMD.btWorld.stepSimulation @delta
              physi.postSimulate @delta

        hasAd= pmx.bones.some (bone)-> bone.additionalTransform
        addTrans= new THREE.MMD.MMDAddTrans pmx, mesh if hasAd

        {mesh,morph,skin,ik,physi,physiPlugin,addTrans}

  {Loader,VpdLoader}
